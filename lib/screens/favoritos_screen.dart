import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  late Future<List<dynamic>> _favoritosFuture;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  void _cargarFavoritos() {
    setState(() {
      _favoritosFuture = ApiService.obtenerFavoritos();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF9FAFB);
    const Color primaryText = Color(0xFF111827);
    const Color secondaryText = Color(0xFF6B7280);
    const Color primaryColor = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white.withOpacity(0.85),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryText),
      ),
      body: Stack(
        children: [
          Container(color: backgroundColor),
          SafeArea(
            child: FutureBuilder<List<dynamic>>(
              future: _favoritosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                } 
                
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                            child: const Icon(Icons.favorite_border_rounded, size: 48, color: Color(0xFFEF4444)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aún no hay favoritos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryText),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Explora el mapa y guarda los lugares que más te gusten presionando el corazón.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: secondaryText, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final comercios = snapshot.data!;

                return ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: comercios.length,
                  itemBuilder: (context, index) {
                    final comercio = comercios[index];
                    final double promedio = double.tryParse(comercio['promedio']?.toString() ?? '0') ?? 0.0;
                    
                    // Aseguramos que la imagen exista, de lo contrario usamos un placeholder
                    final imagenUrl = (comercio['imagen'] != null && comercio['imagen'].toString().isNotEmpty) 
                        ? comercio['imagen'] 
                        : 'https://placehold.co/400x400/4F46E5/FFFFFF.png?text=${comercio['nombre'][0]}';

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // Para que DetailScreen funcione, adaptamos los datos al formato que espera
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetailScreen(
                            lugar: {
                              'id': comercio['id'],
                              'nombre': comercio['nombre'],
                              'categoria': comercio['categoria'],
                              'imagen': imagenUrl,
                              'rating': promedio,
                              'reviews': comercio['total_votos'],
                              'badge': 'Guardado ❤️',
                            },
                          )),
                        ).then((_) => _cargarFavoritos()); // Recarga al volver por si quitó el like
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Imagen miniatura
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                              child: Image.network(
                                imagenUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Información
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12).copyWith(right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comercio['nombre'],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryText, letterSpacing: -0.3),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comercio['categoria'],
                                      style: const TextStyle(fontSize: 13, color: secondaryText, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          promedio.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryText),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Botón de eliminar (Corazón rojo roto)
                            IconButton(
                              icon: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await ApiService.toggleFavorito(comercio['id']);
                                _cargarFavoritos(); // Refrescamos la lista localmente
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}