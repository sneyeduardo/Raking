import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingScreen extends StatefulWidget {
  final String nfcCodigo;
  
  const RatingScreen({super.key, required this.nfcCodigo});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final String _baseUrl = 'http://26.59.102.18:3000';
  Map<String, dynamic>? _comercioData;
  bool _isLoading = true;
  double _ratingSeleccionado = 0;

  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _primaryText = const Color(0xFF111827);
  final Color _secondaryText = const Color(0xFF6B7280);
  final Color _backgroundColor = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _fetchComercioData();
  }

  Future<void> _fetchComercioData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/comercios/nfc/${widget.nfcCodigo}'));
      if (response.statusCode == 200) {
        setState(() {
          _comercioData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarVoto() async {
    if (_ratingSeleccionado == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecciona una calificación', style: TextStyle(color: Colors.white)),
          backgroundColor: _primaryText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Mostramos un indicador de carga mientras enviamos al servidor
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/comercios/votar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nfc_codigo': widget.nfcCodigo,
          'rating': _ratingSeleccionado,
        }),
      );

      // Cerramos el indicador de carga
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        _mostrarExitoAnimado();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Cierra el loader en caso de error
      debugPrint('Error: $e');
    }
  }

  void _mostrarExitoAnimado() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 50),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '¡Excelente!',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu opinión ayuda a miles de personas a descubrir los mejores lugares.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    // Cerramos el modal de éxito y la pantalla de calificación automáticamente después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Cierra el modal
        Navigator.pop(context); // Regresa a la pantalla anterior
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    if (_comercioData == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          iconTheme: IconThemeData(color: _primaryText),
        ),
        body: Center(
          child: Text('Local no encontrado', style: TextStyle(color: _primaryText, fontWeight: FontWeight.w600)),
        ),
      );
    }

    final double promedio = double.tryParse(_comercioData?['promedio']?.toString() ?? '0.0') ?? 0.0;
    final int totalVotos = int.tryParse(_comercioData?['total_votos']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.85),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(color: _backgroundColor),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storefront_rounded, size: 40, color: _primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _comercioData?['nombre'] ?? 'Lugar',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: _primaryText),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _comercioData?['categoria'] ?? 'Categoría',
                          style: TextStyle(fontSize: 14, color: _secondaryText, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                promedio.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                              ),
                              Text(
                                ' ($totalVotos opiniones)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Text(
                    "¿Qué te pareció tu experiencia?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: _primaryText),
                  ),
                  const SizedBox(height: 20),
                  
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                    itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                    onRatingUpdate: (rating) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _ratingSeleccionado = rating;
                      });
                    },
                  ),
                  
                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _enviarVoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Enviar Voto', 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}