import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Importamos Riverpod
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../providers/auth_provider.dart'; // 👈 Importamos el Proveedor
import 'home_screen.dart';
import '../providers/favoritos_provider.dart';
// 1. Cambiamos a ConsumerStatefulWidget para mantener controladores pero leer el estado
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _modoActual = 'login'; 

  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailRegisterController = TextEditingController();
  final _passwordRegisterController = TextEditingController();

  final _emailForgotController = TextEditingController();

  // Ya no necesitamos _isLoading local, usaremos el de Riverpod

  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _primaryText = const Color(0xFF111827);
  final Color _secondaryText = const Color(0xFF6B7280);
  final Color _backgroundColor = const Color(0xFFF9FAFB);

  void _ejecutarLogin() async {
    HapticFeedback.mediumImpact();

    // 2. Usamos el proveedor para iniciar sesión
    final exito = await ref.read(authProvider.notifier).login(
      _emailLoginController.text.trim(), 
      _passwordLoginController.text.trim()
    );

    if (exito) {
      await ref.read(favoritosProvider.notifier).cargarFavoritos();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _mostrarMensaje('Correo o contraseña incorrectos');
    }
  }

  void _ejecutarRegistro() async {
    HapticFeedback.mediumImpact();
    // Para el registro podemos seguir usando el ApiService directamente o moverlo al Notifier,
    // aquí lo mantenemos simple usando el ApiService.
    
    final exito = await ApiService.register(
      nombre: _nameController.text.trim(),
      apellido: _lastNameController.text.trim(),
      correo: _emailRegisterController.text.trim(),
      telefono: _phoneController.text.trim(),
      password: _passwordRegisterController.text,
    );

    if (exito) {
      _mostrarMensaje('¡Registro exitoso! Por favor inicia sesión.', const Color(0xFF059669));
      setState(() => _modoActual = 'login');
    } else {
      _mostrarMensaje('Error al registrar usuario. Verifica tus datos o si el correo ya existe.');
    }
  }

  void _ejecutarRecuperacion() async {
    HapticFeedback.mediumImpact();
    final correo = _emailForgotController.text.trim();

    if (correo.isEmpty) {
      _mostrarMensaje('Por favor, ingresa tu correo electrónico.');
      return;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/auth/forgot-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _mostrarMensaje(data['message'] ?? 'Instrucciones enviadas correctamente.', const Color(0xFF059669));
        setState(() => _modoActual = 'login');
      } else {
        _mostrarMensaje(data['error'] ?? 'Ocurrió un error al procesar la solicitud.');
      }
    } catch (e) {
      debugPrint('Error de conexión: $e');
      _mostrarMensaje('No se pudo conectar con el servidor. Verifica tu conexión.');
    }
  }

  void _mostrarMensaje(String msg, [Color? colorFondo]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: colorFondo ?? Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. Escuchamos el estado global para saber si está cargando
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Container(color: _backgroundColor),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _construirFormularioActual(isLoading),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormularioActual(bool isLoading) {
    switch (_modoActual) {
      case 'register':
        return Column(
          key: const ValueKey('register'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Crea tu Cuenta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Únete al Salón de la Fama', style: TextStyle(fontSize: 14, color: _secondaryText, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            TextField(controller: _nameController, style: TextStyle(color: _primaryText), decoration: _inputDecoration('Nombre', Icons.person_outline_rounded)),
            const SizedBox(height: 12),
            TextField(controller: _lastNameController, style: TextStyle(color: _primaryText), decoration: _inputDecoration('Apellido', Icons.person_add_alt_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _emailRegisterController, style: TextStyle(color: _primaryText), keyboardType: TextInputType.emailAddress, decoration: _inputDecoration('Correo electrónico', Icons.email_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, style: TextStyle(color: _primaryText), keyboardType: TextInputType.phone, decoration: _inputDecoration('Número de teléfono', Icons.phone_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _passwordRegisterController, style: TextStyle(color: _primaryText), obscureText: true, decoration: _inputDecoration('Contraseña', Icons.lock_outline_rounded)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _ejecutarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  elevation: 0,
                ),
                child: isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Registrarse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _modoActual = 'login'),
              child: Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w700)),
            ),
          ],
        );

      case 'forgot':
        return Column(
          key: const ValueKey('forgot'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recuperar Acceso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Te enviaremos los pasos a tu correo', style: TextStyle(fontSize: 14, color: _secondaryText, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(controller: _emailForgotController, style: TextStyle(color: _primaryText), keyboardType: TextInputType.emailAddress, decoration: _inputDecoration('Correo electrónico', Icons.email_outlined)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _ejecutarRecuperacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  elevation: 0,
                ),
                child: const Text('Enviar Instrucciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _modoActual = 'login'),
              child: Text('Volver al Login', style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w600)),
            ),
          ],
        );

      default: // 'login'
        return Column(
          key: const ValueKey('login'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bienvenido a RankSpot', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Ingresa para calificar y competir', style: TextStyle(fontSize: 14, color: _secondaryText, fontWeight: FontWeight.w500)),
            const SizedBox(height: 28),
            TextField(controller: _emailLoginController, style: TextStyle(color: _primaryText), keyboardType: TextInputType.emailAddress, decoration: _inputDecoration('Correo electrónico', Icons.email_outlined)),
            const SizedBox(height: 16),
            TextField(controller: _passwordLoginController, style: TextStyle(color: _primaryText), obscureText: true, decoration: _inputDecoration('Contraseña', Icons.lock_outline_rounded)),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _modoActual = 'forgot'),
                child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: _secondaryText, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _ejecutarLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  elevation: 0,
                ),
                child: isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Iniciar Sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _modoActual = 'register'),
              child: Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w700)),
            ),
          ],
        );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _secondaryText, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _primaryColor, size: 22),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
    );
  }
}