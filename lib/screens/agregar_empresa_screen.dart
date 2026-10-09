import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';

class AgregarEmpresaScreen extends StatefulWidget {
  const AgregarEmpresaScreen({super.key});

  @override
  State<AgregarEmpresaScreen> createState() => _AgregarEmpresaScreenState();
}

class _AgregarEmpresaScreenState extends State<AgregarEmpresaScreen> {
  final _nombreController = TextEditingController();
  final _nfcController = TextEditingController();
  
  // Categorías predefinidas sencillas
  final List<String> _categorias = ['Restaurantes', 'Tecnología', 'Moda', 'Servicios', 'Entretenimiento'];
  String _categoriaSeleccionada = 'Restaurantes';
  bool _isLoading = false;

  void _guardarEmpresa() async {
    if (_nombreController.text.isEmpty || _nfcController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos'), backgroundColor: Color(0xFF0A1128)),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final exito = await ApiService.registrarEmpresa(
      nombre: _nombreController.text,
      categoria: _categoriaSeleccionada,
      nfcCodigo: _nfcController.text,
    );

    setState(() => _isLoading = false);

    if (exito) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Empresa registrada con éxito!'), backgroundColor: Color(0xFF00E5FF)),
      );
      Navigator.pop(context); // Regresa al perfil
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar la empresa (código NFC duplicado o fallo de red)'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Asociar Empresa', style: TextStyle(color: Color(0xFFF4F5F7), fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF4F5F7)), // Blanco Hueso
      ),
      body: Stack(
        children: [
          // Fondo degradado Azul Marino / Azul Pizarra
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1128), Color(0xFF1C2541)],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2541).withOpacity(0.9), // Azul Pizarra
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nuevo Local o Comercio',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFF4F5F7)), // Blanco Hueso
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ingresa los datos básicos para asociarlo al sistema',
                          style: TextStyle(fontSize: 13, color: const Color(0xFFF4F5F7).withOpacity(0.6)),
                        ),
                        const SizedBox(height: 24),

                        // Nombre de la empresa
                        TextField(
                          controller: _nombreController,
                          style: const TextStyle(color: Color(0xFFF4F5F7)),
                          decoration: _inputDecoration('Nombre de la empresa', Icons.business_rounded),
                        ),
                        const SizedBox(height: 16),

                        // Selector de Categoría
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1128), // Azul Marino
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _categoriaSeleccionada,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1C2541), // Fondo del menú desplegable
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00E5FF)),
                              items: _categorias.map((String cat) {
                                return DropdownMenuItem<String>(
                                  value: cat,
                                  child: Text(cat, style: const TextStyle(color: Color(0xFFF4F5F7), fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (String? nuevaCat) {
                                if (nuevaCat != null) {
                                  setState(() => _categoriaSeleccionada = nuevaCat);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Código NFC / QR temporal
                        TextField(
                          controller: _nfcController,
                          style: const TextStyle(color: Color(0xFFF4F5F7)),
                          decoration: _inputDecoration('Código NFC / QR (ej: uuid-9999)', Icons.qr_code_rounded),
                        ),
                        const SizedBox(height: 28),

                        // Botón Guardar con Cian Eléctrico
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarEmpresa,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF), // Cian Eléctrico
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Color(0xFF0A1128))
                                : const Text('Guardar y Asociar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A1128))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: const Color(0xFFF4F5F7).withOpacity(0.6)),
      prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)), // Cian Eléctrico
      filled: true,
      fillColor: const Color(0xFF0A1128), // Fondo Azul Marino para campos de texto
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
    );
  }
}