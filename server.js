const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 3000;
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const BREVO_API_KEY = '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'; // Reemplaza esto
const EMAIL_SENDER = 'sneyeduardo4@gmail.com'; // Debe ser un correo verificado en Brevo
app.use(cors());
app.use(express.json());

// 1. Configuración del Pool de Conexiones a Aiven MySQL
const pool = mysql.createPool({
    uri: 'mysql://avnadmin:AVNS_dsgJ984KpSFsK2VpnpS@corretaje2-sneyeduardo4-a9be.i.aivencloud.com:16420/Raking?ssl-mode=REQUIRED', // Ej: mysql://user:password@host:port/defaultdb
    ssl: {
        rejectUnauthorized: false // Aiven requiere SSL
    },
    enableKeepAlive: true,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Probar conexión al iniciar
// Probar conexión al iniciar y crear las tablas automáticamente
pool.getConnection()
    .then(async (connection) => {
        console.log('✅ Conectado exitosamente a Aiven MySQL');
        
        try {
            // 1. Crear tabla de comercios si no existe
            await connection.execute(`
                CREATE TABLE IF NOT EXISTS comercios (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    nombre VARCHAR(100) NOT NULL,
                    categoria VARCHAR(50),
                    nfc_codigo VARCHAR(100) UNIQUE NOT NULL
                )
            `);
            
            // 2. Crear tabla de calificaciones si no existe
            await connection.execute(`
                CREATE TABLE IF NOT EXISTS calificaciones (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    comercio_id INT NOT NULL,
                    rating DECIMAL(3,1) NOT NULL,
                    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (comercio_id) REFERENCES comercios(id) ON DELETE CASCADE
                )
            `);

            // 3. Insertar el local de prueba (INSERT IGNORE evita errores si ya existe)
            await connection.execute(`
                INSERT IGNORE INTO comercios (nombre, categoria, nfc_codigo) 
                VALUES ('Burger Spot', 'Restaurantes', 'uuid-1234')
            `);

            
            console.log('✅ Tablas verificadas y listas para usar.');
        } catch (error) {
            console.error('❌ Error creando las tablas:', error);
        } finally {
            connection.release(); // Liberamos la conexión para que no se quede colgada
        }
    })
    .catch((err) => console.error('❌ Error conectando a MySQL:', err));

async function enviarCorreoBrevo(toEmail, toName, subject, htmlContent) {
    try {
        await axios.post('https://api.brevo.com/v3/smtp/email', {
            sender: { name: "RankSpot", email: EMAIL_SENDER },
            to: [{ email: toEmail, name: toName }],
            subject: subject,
            htmlContent: htmlContent
        }, {
            headers: { 'api-key': BREVO_API_KEY, 'content-type': 'application/json' }
        });
        console.log(`📧 Correo enviado con éxito a: ${toEmail}`);
    } catch (error) {
        console.error('Error enviando correo Brevo:', error.response?.data || error.message);
    }
}

// ----------------------------------------------------
// 1. RUTA POST: Solicitar recuperación de contraseña
// ----------------------------------------------------
app.post('/api/auth/forgot-password', async (req, res) => {
    const { correo } = req.body;
    try {
        const [users] = await pool.execute('SELECT id, nombre FROM usuarios WHERE correo = ?', [correo]);
        if (users.length === 0) {
            return res.status(404).json({ error: 'No existe una cuenta con este correo.' });
        }

        const token = uuidv4();
        const expires = new Date(Date.now() + 3600000); // Expira en 1 hora

        await pool.execute(
            'UPDATE usuarios SET reset_token = ?, reset_token_expires = ? WHERE correo = ?',
            [token, expires, correo]
        );

        // Este es el Deep Link que Flutter interceptará
        const resetLink = `rankspot://reset?token=${token}`;
        
        const html = `
            <h2>Recuperación de contraseña</h2>
            <p>Hola ${users[0].nombre},</p>
            <p>Has solicitado restablecer tu contraseña. Haz clic en el siguiente enlace desde tu teléfono para cambiarla:</p>
            <a href="${resetLink}" style="padding: 10px 20px; background-color: #14B8A6; color: white; text-decoration: none; border-radius: 8px;">Restablecer Contraseña</a>
            <p>Si no fuiste tú, ignora este mensaje.</p>
        `;

        await enviarCorreoBrevo(correo, users[0].nombre, 'Recupera tu contraseña - RankSpot', html);
        res.json({ message: 'Correo de recuperación enviado.' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error procesando la solicitud.' });
    }
});

// ----------------------------------------------------
// 2. RUTA POST: Restablecer la contraseña
// ----------------------------------------------------
app.post('/api/auth/reset-password', async (req, res) => {
    const { token, nuevaPassword } = req.body;
    try {
        const [users] = await pool.execute(
            'SELECT id FROM usuarios WHERE reset_token = ? AND reset_token_expires > NOW()',
            [token]
        );

        if (users.length === 0) {
            return res.status(400).json({ error: 'El enlace es inválido o ha expirado.' });
        }

        // Actualiza contraseña y limpia el token
        await pool.execute(
            'UPDATE usuarios SET password = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?',
            [nuevaPassword, users[0].id]
        );

        res.json({ message: 'Contraseña actualizada correctamente.' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error restableciendo la contraseña.' });
    }
});

// 2. RUTA GET: Obtener el local por NFC (y calcular su promedio actual)
app.get('/api/comercios/nfc/:codigo', async (req, res) => {
    try {
        const { codigo } = req.params;
        
        // Buscamos el comercio y calculamos el promedio de sus calificaciones en una sola consulta
        const query = `
            SELECT c.id, c.nombre, c.categoria, c.nfc_codigo, 
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos
            FROM comercios c
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            WHERE c.nfc_codigo = ?
            GROUP BY c.id
        `;
        
        const [rows] = await pool.execute(query, [codigo]);

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Comercio no encontrado' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// 3. RUTA POST: Guardar el nuevo voto
app.post('/api/comercios/votar', async (req, res) => {
    try {
        const { nfc_codigo, rating } = req.body;
        
        if (!nfc_codigo || !rating) {
            return res.status(400).json({ error: 'Faltan datos obligatorios' });
        }

        // Primero, obtenemos el ID interno del comercio usando su código NFC
        const [comercios] = await pool.execute(
            'SELECT id FROM comercios WHERE nfc_codigo = ?', 
            [nfc_codigo]
        );

        if (comercios.length === 0) {
            return res.status(404).json({ error: 'Comercio no válido' });
        }

        const comercioId = comercios[0].id;

        // Insertamos el voto en la tabla de calificaciones
        await pool.execute(
            'INSERT INTO calificaciones (comercio_id, rating) VALUES (?, ?)',
            [comercioId, rating]
        );

        console.log(`⭐ Voto real guardado en MySQL: ${rating} estrellas para el ID [${comercioId}]`);
        res.status(200).json({ message: 'Voto registrado exitosamente en la base de datos' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error guardando la calificación' });
    }
});
// REGISTRO DE USUARIO ACTUALIZADO
// REGISTRO DE USUARIO
app.post('/api/auth/register', async (req, res) => {
    try {
        const { nombre, apellido, correo, telefono, password } = req.body;
        if (!nombre || !apellido || !correo || !telefono || !password) {
            return res.status(400).json({ error: 'Todos los campos son obligatorios' });
        }

        // 1. Primero ejecutamos el registro en la base de datos Aiven
const [result] = await pool.execute(
    'INSERT INTO usuarios (nombre, apellido, correo, telefono, password) VALUES (?, ?, ?, ?, ?)',
    [nombre, apellido, correo, telefono, password]
);

// 2. Definimos el contenido del correo de bienvenida
const htmlBienvenida = `
    <h2>¡Hola ${nombre}!,</h2>
    <p>Gracias por unirte a <strong>RankSpot</strong>. Estamos felices de tenerte aquí.</p>
    <p>Ya puedes iniciar sesión y comenzar a explorar o calificar los mejores lugares.</p>
`;

// 3. Enviamos el correo de bienvenida a través de Brevo
await enviarCorreoBrevo(correo, nombre, '¡Bienvenido a RankSpot!', htmlBienvenida);

// 4. Respondemos al cliente de Flutter que todo salió bien
res.status(201).json({ message: 'Usuario registrado exitosamente' });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ error: 'El correo electrónico ya está registrado' });
        }
        console.error(error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
});
// 2. LOGIN DE USUARIO
app.post('/api/auth/login', async (req, res) => {
    try {
        const { correo, password } = req.body;
        
        // Seleccionamos también el rol
        const [rows] = await pool.execute(
            'SELECT id, nombre, apellido, correo, rol FROM usuarios WHERE correo = ? AND password = ?',
            [correo, password]
        );

        if (rows.length === 0) {
            return res.status(401).json({ error: 'Correo o contraseña incorrectos' });
        }

        res.json({ 
            message: 'Login exitoso', 
            usuario: rows[0] // 👈 Aquí va el rol incluido (ej: rows[0].rol = 'admin')
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
});
// RUTA POST: Registrar una nueva empresa / comercio
app.post('/api/comercios/registrar', async (req, res) => {
    try {
        const { nombre, categoria, nfc_codigo } = req.body;
        
        if (!nombre || !categoria || !nfc_codigo) {
            return res.status(400).json({ error: 'Faltan datos obligatorios' });
        }

        await pool.execute(
            'INSERT INTO comercios (nombre, categoria, nfc_codigo) VALUES (?, ?, ?)',
            [nombre, categoria, nfc_codigo]
        );

        console.log(`🏢 Nueva empresa registrada en MySQL: ${nombre} (${categoria})`);
        res.status(201).json({ message: 'Empresa registrada exitosamente' });

    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ error: 'El código NFC o identificador ya está registrado' });
        }
        console.error(error);
        res.status(500).json({ error: 'Error registrando la empresa' });
    }
});
// RUTA GET: Obtener comercios por categoría ordenados por mejor ranking
app.get('/api/comercios/categoria/:categoria', async (req, res) => {
    try {
        const { categoria } = req.params;
        
        const query = `
            SELECT c.id, c.nombre, c.categoria, c.nfc_codigo, 
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos
            FROM comercios c
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            WHERE c.categoria = ?
            GROUP BY c.id
            ORDER BY promedio DESC
        `;
        
        const [rows] = await pool.execute(query, [categoria]);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error obteniendo el ranking por categoría' });
    }
});
app.listen(port, () => {
    console.log(`🚀 API conectada a MySQL corriendo en http://localhost:${port}`);
});