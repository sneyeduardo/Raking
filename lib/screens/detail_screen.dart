import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:ui';
import '../services/api_service.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> lugar;
  final String? heroTag;

  const DetailScreen({super.key, required this.lugar, this.heroTag});

  

  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _primaryText = const Color(0xFF111827);
  final Color _secondaryText = const Color(0xFF6B7280);
  final Color _backgroundColor = const Color(0xFFF9FAFB);

  Future<void> _iniciarEscaneoQR(BuildContext context) async {
    HapticFeedback.mediumImpact();
    
    // Si estamos probando en Web, saltamos la cámara y mostramos el modal directamente[cite: 5]
    if (kIsWeb) {
      _mostrarModalCalificacion(context, "Modo Web Activo (QR simulado)");
      return;
    }

    try {
      // Abre la cámara nativa para leer el QR con la nueva librería[cite: 5]
      var result = await BarcodeScanner.scan(
        options: const ScanOptions(
          restrictFormat: [BarcodeFormat.qr],
        ),
      );

      if (result.rawContent.isNotEmpty) {
        if (!context.mounted) return;
        _mostrarModalCalificacion(context, result.rawContent);
      }
    } on PlatformException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al acceder a la cámara del dispositivo.')),
      );
    }
  }

  void _mostrarModalCalificacion(BuildContext context, String qrData) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        int ratingSeleccionado = 0;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 24),
                        Icon(Icons.check_circle_rounded, color: _primaryColor, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '¡Visita Verificada!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Has validado tu presencia en ${lugar['nombre']}',
                          style: TextStyle(color: _secondaryText, fontSize: 14, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Text('¿Qué tal estuvo tu experiencia?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _primaryText)),
                        const SizedBox(height: 16),
                        
                        // Selector de Estrellas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => ratingSeleccionado = index + 1);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  index < ratingSeleccionado ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: index < ratingSeleccionado ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                                  size: 40,
                                ),
                              ),
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Botón de Envío
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: ratingSeleccionado == 0 ? null : () async {
                              HapticFeedback.mediumImpact();
                              
                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                      const SizedBox(width: 16),
                                      const Text('Guardando calificación...', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: _primaryText,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );

                              bool exito = await ApiService.enviarCalificacion(
                                qrData: qrData, 
                                rating: ratingSeleccionado
                              );

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              if (exito) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('¡Calificación guardada exitosamente! 🎉', style: TextStyle(color: Colors.white)),
                                    backgroundColor: _primaryText,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Hubo un error al conectar con el servidor.', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              disabledBackgroundColor: const Color(0xFFE5E7EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Publicar Calificación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            stretch: true,
            backgroundColor: _backgroundColor,
            elevation: 0,
            // ... (tu leading back button se mantiene)
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag ?? 'imagen-${lugar['nombre']}', // <--- Recibe la animación
                    child: Image.network(lugar['imagen'] ?? '', fit: BoxFit.cover),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white], // Transición suave hacia el fondo blanco
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lugar['categoria']?.toUpperCase() ?? 'CATEGORÍA',
                        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2),
                      ),
                      if (lugar['badge'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7), 
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lugar['badge'], 
                            style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lugar['nombre'] ?? 'Nombre del Local', 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: _primaryText),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 26),
                      const SizedBox(width: 8),
                      Text(
                        lugar['rating']?.toString() ?? '0.0', 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryText),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${lugar['reviews']} opiniones verificadas)', 
                        style: TextStyle(fontSize: 14, color: _secondaryText, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Sobre este lugar', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryText),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Este es uno de los locales mejor valorados de la zona. Destaca por su excelente servicio al cliente y ambiente inigualable.', 
                    style: TextStyle(fontSize: 15, height: 1.5, color: _secondaryText, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoRow(Icons.location_on_rounded, 'Av. Principal, Caracas, Miranda'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.access_time_rounded, 'Abierto ahora • Cierra a las 10:00 PM'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 56,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _iniciarEscaneoQR(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Escanear QR', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Icon(icon, color: _primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _secondaryText),
          ),
        ),
      ],
    );
  }
}