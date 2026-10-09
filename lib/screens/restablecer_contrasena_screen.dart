import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';

class RestablecerContrasenaScreen extends StatefulWidget {
  final String token;

  const RestablecerContrasenaScreen({super.key, required this.token});

  @override
  State<RestablecerContrasenaScreen> createState() => _RestablecerContrasenaScreenState();
}

class _RestablecerContrasenaScreenState extends State<RestablecerContrasenaScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _ocultarPassword = true;

  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _primaryText = const Color(0xFF111827);
  final Color _secondaryText = const Color(0xFF6B7280);
  final Color _backgroundColor = const Color(0xFFF9FAFB);

  void _guardarNuevaContrasena() async {
    final pass = _passwordController.text;
    final conf = _confirmController.text;

    if (pass.isEmpty || conf.isEmpty) {
      _mostrarMensaje('Llena ambos campos', _primaryText);
      return;
    }
    if (pass != conf) {
      _mostrarMensaje('Las contraseñas no coinciden', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Llama al backend con el token extraído del deep link
    final exito = await ApiService.restablecerContrasena(widget.token, pass);

    setState(() => _isLoading = false);

    if (exito) {
      _mostrarMensaje('¡Contraseña actualizada! Ya puedes iniciar sesión', _primaryText);
      if (!mounted) return;
      // Cierra esta pantalla y regresa directamente al Login
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      _mostrarMensaje('El enlace expiró o es inválido', Colors.redAccent);
    }
  }

  void _mostrarMensaje(String texto, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(color: _backgroundColor),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.password_rounded, size: 28, color: _primaryColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nueva Contraseña', 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ingresa tu nueva contraseña para acceder a tu cuenta.', 
                      style: TextStyle(color: _secondaryText, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),

                    // Campo Nueva Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: _ocultarPassword,
                      style: TextStyle(color: _primaryText),
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        labelStyle: TextStyle(color: _secondaryText, fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: _primaryColor, size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _secondaryText),
                          onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo Confirmar Contraseña
                    TextField(
                      controller: _confirmController,
                      obscureText: _ocultarPassword,
                      style: TextStyle(color: _primaryText),
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        labelStyle: TextStyle(color: _secondaryText, fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.lock_reset_rounded, color: _primaryColor, size: 22),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarNuevaContrasena,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Actualizar Contraseña', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}