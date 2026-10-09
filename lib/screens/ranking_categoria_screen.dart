import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../providers/favoritos_provider.dart';
import 'detail_screen.dart';
import 'resenas_modal.dart';
class RankingCategoriaScreen extends ConsumerStatefulWidget {
  final String categoria;

  const RankingCategoriaScreen({super.key, required this.categoria});

  @override
  ConsumerState<RankingCategoriaScreen> createState() => _RankingCategoriaScreenState();
}

class _RankingCategoriaScreenState extends ConsumerState<RankingCategoriaScreen> {
  List<dynamic> _comerciosOriginales = [];
  List<dynamic> _comerciosFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final Color _primaryText = const Color(0xFF111827);
  final Color _secondaryText = const Color(0xFF6B7280);
  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _backgroundColor = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _cargarComercios();
    _searchController.addListener(_filtrarBusqueda);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarComercios() async {
    final comercios = await ApiService.obtenerComerciosPorCategoria(widget.categoria);
    if (mounted) {
      setState(() {
        _comerciosOriginales = comercios;
        _comerciosFiltrados = comercios;
        _isLoading = false;
      });
    }
  }

  void _filtrarBusqueda() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _comerciosFiltrados = _comerciosOriginales.where((comercio) {
        final nombre = comercio['nombre'].toString().toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Header Dinámico con Buscador
          SliverAppBar(
            expandedHeight: 160.0,
            pinned: true,
            backgroundColor: Colors.white.withOpacity(0.9),
            elevation: 0,
            iconTheme: IconThemeData(color: _primaryText),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 84),
                  title: Text(
                    widget.categoria,
                    style: TextStyle(color: _primaryText, fontWeight: FontWeight.w900, letterSpacing: -0.5, fontSize: 20),
                  ),
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(bottom: 20),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: _primaryText, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Buscar en ${widget.categoria}...',
                              hintStyle: TextStyle(color: _secondaryText, fontSize: 15, fontWeight: FontWeight.w500),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Listado de Resultados
          if (_isLoading)
            SliverToBoxAdapter(child: _buildSkeletonLoader())
          else if (_comerciosFiltrados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                      child: Icon(Icons.search_off_rounded, size: 48, color: _primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text('No encontramos resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryText)),
                    const SizedBox(height: 8),
                    Text('Intenta buscar con otras palabras.', style: TextStyle(fontSize: 14, color: _secondaryText, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comercio = _comerciosFiltrados[index];
                    return _buildComercioCard(comercio, index);
                  },
                  childCount: _comerciosFiltrados.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComercioCard(Map<String, dynamic> comercio, int index) {
    final double promedio = double.tryParse(comercio['promedio']?.toString() ?? '0') ?? 0.0;
    final int totalVotos = comercio['total_votos'] ?? 0;
    final int comercioId = int.tryParse(comercio['id']?.toString() ?? '0') ?? 0;
    final bool esPrimerLugar = index == 0 && _searchController.text.isEmpty;

    final String imagenUrl = (comercio['imagen'] != null && comercio['imagen'].toString().isNotEmpty) 
        ? comercio['imagen'] 
        : 'https://placehold.co/400x400/4F46E5/FFFFFF.png?text=${comercio['nombre'][0]}';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(
            lugar: {
              'id': comercioId,
              'nombre': comercio['nombre'],
              'categoria': comercio['categoria'],
              'imagen': imagenUrl,
              'rating': promedio,
              'reviews': totalVotos,
              'badge': esPrimerLugar ? 'Top #1 🔥' : 'Destacado',
            },
          )),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: esPrimerLugar ? const Color(0xFFF59E0B).withOpacity(0.5) : const Color(0xFFF3F4F6), 
            width: esPrimerLugar ? 1.5 : 1
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            // Parte Superior: Imagen, Título y Corazón
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  child: Stack(
                    children: [
                      Image.network(imagenUrl, width: 110, height: 110, fit: BoxFit.cover),
                      if (esPrimerLugar)
                        Positioned(
                          top: 0, left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
                            ),
                            child: const Text('#1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                comercio['nombre'],
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryText, letterSpacing: -0.5),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Botón Favoritos (Riverpod)
                            Consumer(
                              builder: (context, ref, _) {
                                final favoritos = ref.watch(favoritosProvider);
                                final esFavorito = favoritos.contains(comercioId);

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (comercioId != 0) {
                                      ref.read(favoritosProvider.notifier).toggleFavorito(comercioId);
                                    }
                                  },
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                    child: Icon(
                                      esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      key: ValueKey(esFavorito),
                                      color: esFavorito ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
                                      size: 24,
                                    ),
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                  const SizedBox(width: 4),
                                  Text(promedio.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$totalVotos opiniones', style: TextStyle(color: _secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Parte Inferior: Botón de Comentarios
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // AQUÍ IRÁ LA NAVEGACIÓN A LA PANTALLA DE RESEÑAS
                    ResenasModal.mostrar(context, comercioId, comercio['nombre']);                    
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _primaryColor),
                        const SizedBox(width: 8),
                        Text('Leer y dejar reseñas', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: List.generate(4, (index) => 
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
            ),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFF3F4F6),
              highlightColor: Colors.white,
              child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            ),
          ),
        ),
      ),
    );
  }
}