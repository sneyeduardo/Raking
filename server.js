require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const port = process.env.PORT || 3000;
const EMAIL_SENDER = 'sneyeduardo4@gmail.com';

app.use(cors());
app.use(express.json());

// 1. Configuración del Pool Aiven MySQL


if (!process.env.DB_URI) {
    console.error("❌ ERROR: La variable de entorno DB_URI no está definida.");
    process.exit(1);
}

const pool = mysql.createPool({
    uri: process.env.DB_URI,
    ssl: { rejectUnauthorized: false },
    enableKeepAlive: true,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

module.exports = pool;

// Inicialización y Migración de Tablas Seguras
pool.getConnection()
    .then(async (connection) => {
        console.log('✅ Conectado exitosamente a Aiven MySQL');
        try {
            await connection.execute(`
                CREATE TABLE IF NOT EXISTS usuarios (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    nombre VARCHAR(50) NOT NULL,
                    apellido VARCHAR(50) NOT NULL,
                    correo VARCHAR(100) UNIQUE NOT NULL,
                    telefono VARCHAR(20),
                    password VARCHAR(255) NOT NULL,
                    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    rol VARCHAR(20) DEFAULT 'usuario',
                    reset_token VARCHAR(255),
                    reset_token_expires DATETIME
                )
            `);

            await connection.execute(`
                CREATE TABLE IF NOT EXISTS comercios (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    nombre VARCHAR(100) NOT NULL,
                    categoria VARCHAR(50),
                    nfc_codigo VARCHAR(100) UNIQUE NOT NULL,
                    imagen VARCHAR(255),
                    direccion VARCHAR(255),
                    latitud DECIMAL(10, 8),
                    longitud DECIMAL(11, 8)
                )
            `);
            
            await connection.execute(`
                CREATE TABLE IF NOT EXISTS calificaciones (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    comercio_id INT NOT NULL,
                    usuario_id INT NOT NULL,
                    rating DECIMAL(3,1) NOT NULL,
                    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (comercio_id) REFERENCES comercios(id) ON DELETE CASCADE,
                    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
                    UNIQUE KEY unique_voto (comercio_id, usuario_id)
                )
            `);

            await connection.execute(`
                CREATE TABLE IF NOT EXISTS favoritos (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    usuario_id INT NOT NULL,
                    comercio_id INT NOT NULL,
                    fecha_guardado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
                    FOREIGN KEY (comercio_id) REFERENCES comercios(id) ON DELETE CASCADE,
                    UNIQUE KEY unique_favorito (usuario_id, comercio_id)
                )
            `);

            // NUEVO: Tabla de reseñas asegurada al iniciar el servidor
            await connection.execute(`
                CREATE TABLE IF NOT EXISTS resenas (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    comercio_id INT NOT NULL,
                    usuario_id INT NOT NULL,
                    comentario TEXT NOT NULL,
                    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (comercio_id) REFERENCES comercios(id) ON DELETE CASCADE,
                    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
                )
            `);
            
            await connection.execute(`
                INSERT IGNORE INTO comercios (nombre, categoria, nfc_codigo, direccion) 
                VALUES ('Burger Spot', 'Restaurantes', 'uuid-1234', 'Caracas, Miranda')
            `);

            console.log('✅ Tablas verificadas y listas para usar.');
        } catch (error) {
            console.error('❌ Error creando las tablas:', error);
        } finally {
            connection.release();
        }
    })
    .catch(err => console.error('❌ Error conectando a MySQL:', err));

// Middleware de Autenticación JWT
const verificarToken = (req, res, next) => {
    const token = req.header('Authorization')?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Acceso denegado. Token no proporcionado.' });

    try {
        const verificado = jwt.verify(token, process.env.JWT_SECRET);
        req.usuario = verificado;
        next();
    } catch (error) {
        res.status(400).json({ error: 'Token inválido o expirado.' });
    }
};

// Utilidad de Correo Brevo
async function enviarCorreoBrevo(toEmail, toName, subject, htmlContent) {
    try {
        await axios.post('https://api.brevo.com/v3/smtp/email', {
            sender: { name: "RankSpot", email: EMAIL_SENDER },
            to: [{ email: toEmail, name: toName }],
            subject: subject,
            htmlContent: htmlContent
        }, {
            headers: { 'api-key': process.env.BREVO_API_KEY, 'content-type': 'application/json' }
        });
        console.log(`📧 Correo enviado con éxito a: ${toEmail}`);
    } catch (error) {
        console.error('Error enviando correo Brevo:', error.response?.data || error.message);
    }
}

// ----------------------------------------------------
// RUTAS DE AUTENTICACIÓN Y RECUPERACIÓN
// ----------------------------------------------------

app.post('/api/auth/register', async (req, res) => {
    try {
        const { nombre, apellido, correo, telefono, password } = req.body;
        if (!nombre || !apellido || !correo || !telefono || !password) {
            return res.status(400).json({ error: 'Todos los campos son obligatorios' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        await pool.execute(
            'INSERT INTO usuarios (nombre, apellido, correo, telefono, password) VALUES (?, ?, ?, ?, ?)',
            [nombre, apellido, correo, telefono, hashedPassword]
        );

        const htmlBienvenida = `
            <h2>¡Hola ${nombre}!,</h2>
            <p>Gracias por unirte a <strong>RankSpot</strong>. Estamos felices de tenerte aquí.</p>
            <p>Ya puedes iniciar sesión y comenzar a explorar o calificar los mejores lugares.</p>
        `;
        await enviarCorreoBrevo(correo, nombre, '¡Bienvenido a RankSpot!', htmlBienvenida);

        res.status(201).json({ message: 'Usuario registrado exitosamente' });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') return res.status(400).json({ error: 'El correo electrónico ya está registrado' });
        console.error(error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { correo, password } = req.body;
        const [rows] = await pool.execute('SELECT * FROM usuarios WHERE correo = ?', [correo]);

        if (rows.length === 0) return res.status(401).json({ error: 'Correo o contraseña incorrectos' });

        const usuario = rows[0];
        const validPassword = await bcrypt.compare(password, usuario.password);
        if (!validPassword) return res.status(401).json({ error: 'Correo o contraseña incorrectos' });

        const token = jwt.sign(
            { id: usuario.id, rol: usuario.rol },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );

        delete usuario.password;
        res.json({ message: 'Login exitoso', token, usuario });
    } catch (error) {
        console.error('❌ ERROR CRÍTICO EN LOGIN:', error);
        res.status(500).json({ error: 'Error en el servidor', detalle: error.message });
    }
});

app.post('/api/auth/forgot-password', async (req, res) => {
    const { correo } = req.body;
    if (!correo) return res.status(400).json({ error: 'El correo electrónico es requerido.' });

    try {
        const [users] = await pool.execute('SELECT id, nombre FROM usuarios WHERE correo = ?', [correo]);
        if (users.length === 0) return res.status(404).json({ error: 'No existe una cuenta con este correo.' });

        const token = uuidv4();
        const expires = new Date(Date.now() + 3600000);

        await pool.execute(
            'UPDATE usuarios SET reset_token = ?, reset_token_expires = ? WHERE correo = ?',
            [token, expires, correo]
        );

        const resetLink = `http://26.59.102.18:3000/api/auth/redirect-reset?token=${token}`;
        const html = `
            <h2>¡Hola, ${users[0].nombre}!</h2>
            <p>Recibimos una solicitud para restablecer tu contraseña. Haz clic en el enlace para continuar:</p>
            <a href="${resetLink}">Restablecer Contraseña</a>
            <p>Este enlace expira en 1 hora.</p>
        `;

        await enviarCorreoBrevo(correo, users[0].nombre, 'Restablece tu contraseña - RankSpot', html);
        res.status(200).json({ message: 'Correo de recuperación enviado exitosamente.' });
    } catch (error) {
        console.error('Error en forgot-password:', error);
        res.status(500).json({ error: 'Error al procesar tu solicitud.' });
    }
});

app.get('/api/auth/redirect-reset', (req, res) => {
    const { token } = req.query;
    if (!token) return res.status(400).send('Token no proporcionado.');
    res.redirect(`rankspot://reset?token=${token}`);
});

app.post('/api/auth/reset-password', async (req, res) => {
    const { token, nuevaPassword } = req.body;
    try {
        const [users] = await pool.execute(
            'SELECT id FROM usuarios WHERE reset_token = ? AND reset_token_expires > NOW()',
            [token]
        );

        if (users.length === 0) return res.status(400).json({ error: 'El enlace es inválido o ha expirado.' });

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(nuevaPassword, salt);

        await pool.execute(
            'UPDATE usuarios SET password = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?',
            [hashedPassword, users[0].id]
        );

        res.json({ message: 'Contraseña actualizada correctamente.' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error restableciendo la contraseña.' });
    }
});

// ----------------------------------------------------
// RUTAS DE COMERCIOS Y VOTOS
// ----------------------------------------------------

app.post('/api/comercios/registrar', async (req, res) => {
    try {
        const { nombre, categoria, imagen, direccion } = req.body;
        
        if (!nombre || !categoria) {
            return res.status(400).json({ error: 'Faltan datos obligatorios' });
        }

        const nfc_codigo = (req.body.nfc_codigo && req.body.nfc_codigo.trim() !== '') 
            ? req.body.nfc_codigo.trim() 
            : `spot-${uuidv4().slice(0, 8)}`;

        await pool.execute(
            'INSERT INTO comercios (nombre, categoria, nfc_codigo, imagen, direccion) VALUES (?, ?, ?, ?, ?)',
            [nombre.trim(), categoria, nfc_codigo, imagen || null, direccion || 'Caracas, Miranda']
        );

        res.status(201).json({ message: 'Empresa registrada exitosamente', qr_codigo: nfc_codigo });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') return res.status(400).json({ error: 'El código QR/NFC ya está registrado' });
        console.error(error);
        res.status(500).json({ error: 'Error registrando la empresa' });
    }
});

// CORREGIDO: Ahora incluye c.imagen y c.direccion y ordena por promedio y volumen de votos
app.get('/api/comercios/categoria/:categoria', async (req, res) => {
    try {
        const query = `
            SELECT c.id, c.nombre, c.categoria, c.nfc_codigo, c.imagen, c.direccion,
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos
            FROM comercios c
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            WHERE c.categoria = ?
            GROUP BY c.id
            ORDER BY promedio DESC, total_votos DESC
        `;
        const [rows] = await pool.execute(query, [req.params.categoria]);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error obteniendo el ranking' });
    }
});

app.get('/api/comercios/nfc/:codigo', async (req, res) => {
    try {
        const query = `
            SELECT c.*, 
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos
            FROM comercios c
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            WHERE c.nfc_codigo = ?
            GROUP BY c.id
        `;
        const [rows] = await pool.execute(query, [req.params.codigo]);
        if (rows.length === 0) return res.status(404).json({ error: 'Comercio no encontrado' });
        res.json(rows[0]);
    } catch (error) {
        res.status(500).json({ error: 'Error interno' });
    }
});

// MEJORADO: Registra las estrellas y opcionalmente el comentario en el mismo paso
app.post('/api/comercios/votar', verificarToken, async (req, res) => {
    try {
        const { nfc_codigo, rating, comentario } = req.body;
        const usuario_id = req.usuario.id;

        const [comercios] = await pool.execute('SELECT id, nombre FROM comercios WHERE nfc_codigo = ?', [nfc_codigo]);
        
        if (comercios.length === 0) {
            return res.status(404).json({ error: 'Comercio no encontrado' });
        }
        
        const comercio_id = comercios[0].id;

        // 1. Insertamos o actualizamos las estrellas
        await pool.execute(
            `INSERT INTO calificaciones (comercio_id, usuario_id, rating) 
             VALUES (?, ?, ?) 
             ON DUPLICATE KEY UPDATE rating = ?, fecha = CURRENT_TIMESTAMP`,
            [comercio_id, usuario_id, rating, rating]
        );

        // 2. Si el usuario escribió un comentario o seleccionó etiquetas, lo guardamos en resenas
        if (comentario && comentario.trim() !== '') {
            await pool.execute(
                'INSERT INTO resenas (comercio_id, usuario_id, comentario) VALUES (?, ?, ?)',
                [comercio_id, usuario_id, comentario.trim()]
            );
        }

        res.status(200).json({ message: 'Voto registrado exitosamente', comercio_id });
    } catch (error) {
        console.error('Error al registrar calificación:', error);
        res.status(500).json({ error: 'Error interno al guardar la calificación' });
    }
});

// ----------------------------------------------------
// RUTAS DE FAVORITOS
// ----------------------------------------------------

app.post('/api/comercios/favoritos/toggle', verificarToken, async (req, res) => {
    try {
        const { comercio_id } = req.body;
        const usuario_id = req.usuario.id;

        const [existe] = await pool.execute(
            'SELECT id FROM favoritos WHERE usuario_id = ? AND comercio_id = ?',
            [usuario_id, comercio_id]
        );

        if (existe.length > 0) {
            await pool.execute('DELETE FROM favoritos WHERE id = ?', [existe[0].id]);
            return res.json({ message: 'Eliminado de favoritos', isFavorite: false });
        } else {
            await pool.execute(
                'INSERT INTO favoritos (usuario_id, comercio_id) VALUES (?, ?)',
                [usuario_id, comercio_id]
            );
            return res.json({ message: 'Añadido a favoritos', isFavorite: true });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error procesando favorito' });
    }
});

// Ruta para obtener todos los favoritos del usuario actual
app.get('/api/comercios/favoritos', verificarToken, async (req, res) => {
    try {
        const usuario_id = req.usuario.id;
        const query = `
            SELECT c.id, c.nombre, c.categoria, c.nfc_codigo, c.imagen, c.direccion,
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos,
                   MAX(f.fecha_guardado) as ultima_fecha
            FROM favoritos f
            JOIN comercios c ON f.comercio_id = c.id
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            WHERE f.usuario_id = ?
            GROUP BY c.id
            ORDER BY ultima_fecha DESC
        `;
        const [rows] = await pool.execute(query, [usuario_id]);
        res.json(rows);
    } catch (error) {
        console.error('❌ Error en GET /api/comercios/favoritos:', error);
        res.status(500).json({ error: 'Error obteniendo favoritos', detalle: error.message });
    }
});
// Top de Comercios Globales
app.get('/api/comercios/top', async (req, res) => {
    try {
        const query = `
            SELECT c.id, c.nombre, c.categoria, c.nfc_codigo, c.imagen, c.direccion,
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos
            FROM comercios c
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            GROUP BY c.id
            ORDER BY promedio DESC, total_votos DESC
            LIMIT 10
        `;
        const [rows] = await pool.execute(query);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error obteniendo el top de comercios' });
    }
});

// NUEVO: Actividad reciente en vivo para RankingsView
app.get('/api/comercios/actividad', async (req, res) => {
    try {
        const query = `
            SELECT cal.rating, cal.fecha, 
                   u.nombre AS usuario_nombre, u.apellido AS usuario_apellido,
                   c.id AS comercio_id, c.nombre AS comercio_nombre, c.categoria, c.imagen, c.nfc_codigo
            FROM calificaciones cal
            JOIN usuarios u ON cal.usuario_id = u.id
            JOIN comercios c ON cal.comercio_id = c.id
            ORDER BY cal.fecha DESC
            LIMIT 10
        `;
        const [rows] = await pool.execute(query);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error obteniendo actividad reciente' });
    }
});

// ----------------------------------------------------
// RUTAS DE RESEÑAS (COMENTARIOS + ESTRELLAS)
// ----------------------------------------------------

// MEJORADO: Devuelve también las estrellas (rating) que el usuario le dio al comercio
app.get('/api/comercios/resenas/:comercioId', async (req, res) => {
    try {
        const { comercioId } = req.params;
        const query = `
            SELECT r.id, r.comentario, r.fecha, u.nombre, u.apellido,
                   cal.rating
            FROM resenas r
            JOIN usuarios u ON r.usuario_id = u.id
            LEFT JOIN calificaciones cal ON cal.comercio_id = r.comercio_id AND cal.usuario_id = r.usuario_id
            WHERE r.comercio_id = ?
            ORDER BY r.fecha DESC
        `;
        const [rows] = await pool.execute(query, [comercioId]);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error obteniendo las reseñas' });
    }
});

app.post('/api/comercios/resenas', verificarToken, async (req, res) => {
    try {
        const { comercio_id, comentario } = req.body;
        const usuario_id = req.usuario.id;

        if (!comentario || comentario.trim() === '') {
            return res.status(400).json({ error: 'El comentario no puede estar vacío' });
        }

        await pool.execute(
            'INSERT INTO resenas (comercio_id, usuario_id, comentario) VALUES (?, ?, ?)',
            [comercio_id, usuario_id, comentario.trim()]
        );

        res.status(201).json({ message: 'Reseña publicada exitosamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error publicando la reseña' });
    }
});
// GET: Obtener todos los comercios registrados (Para el panel de Admin)
app.get('/api/comercios/todos', verificarToken, async (req, res) => {
    try {
        const query = `
            SELECT c.id, c.nombre, c.categoria, c.nfc_codigo, c.imagen, c.direccion,
                   IFNULL(AVG(cal.rating), 0) as promedio,
                   COUNT(cal.id) as total_votos
            FROM comercios c
            LEFT JOIN calificaciones cal ON c.id = cal.comercio_id
            GROUP BY c.id
            ORDER BY c.id DESC
        `;
        const [rows] = await pool.execute(query);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error obteniendo la lista de comercios' });
    }
});

// DELETE: Eliminar un comercio (Solo Admin)
app.delete('/api/comercios/:id', verificarToken, async (req, res) => {
    try {
        if (req.usuario.rol !== 'admin') {
            return res.status(403).json({ error: 'No tienes permisos de administrador' });
        }
        await pool.execute('DELETE FROM comercios WHERE id = ?', [req.params.id]);
        res.json({ message: 'Comercio eliminado correctamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error eliminando el comercio' });
    }
});
app.listen(port, () => {
    console.log(`🚀 API Segura conectada a MySQL corriendo en el puerto ${port}`);
});
