import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/favoritos_provider.dart';
import 'rankings_view.dart';
import 'profile_view.dart';
import 'detail_screen.dart';
import 'ranking_categoria_screen.dart';
import 'favoritos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  // 👇 VARIABLES DINÁMICAS PARA EL TOP DE LUGARES
  List<dynamic> _topLugares = [];
  bool _isLoadingTop = true;

  @override
  void initState() {
    super.initState();
    _cargarTopLugares(); // Carga la data real de MySQL al iniciar
  }

  // 👇 MÉTODO QUE LLAMA A LA BASE DE DATOS
  Future<void> _cargarTopLugares() async {
    final top = await ApiService.obtenerTopComercios();
    if (mounted) {
      setState(() {
        _topLugares = top;
        _isLoadingTop = false;
      });
    }
  }

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Restaurantes', 'icono': Icons.restaurant_rounded, 'color': const Color(0xFFFEE2E2), 'iconColor': const Color(0xFFEF4444)},
    {'nombre': 'Deportes', 'icono': Icons.sports_basketball_rounded, 'color': const Color(0xFFE0E7FF), 'iconColor': const Color(0xFF4F46E5)},
    {'nombre': 'Tecnología', 'icono': Icons.devices_rounded, 'color': const Color(0xFFFEF3C7), 'iconColor': const Color(0xFFD97706)},
    {'nombre': 'Cafeterías', 'icono': Icons.coffee_rounded, 'color': const Color(0xFFD1FAE5), 'iconColor': const Color(0xFF059669)},
    {'nombre': 'Moda', 'icono': Icons.checkroom_rounded, 'color': const Color(0xFFFCE7F3), 'iconColor': const Color(0xFFDB2777)},
  ];

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF9FAFB);
    const Color primaryText = Color(0xFF111827);
    const Color primaryColor = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(color: backgroundColor),
          
          _buildBody(),
          
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedOpacity(
                opacity: _isMenuOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            top: _isMenuOpen ? MediaQuery.of(context).padding.top + 70 : -400.0,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _isMenuOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(Icons.location_on_rounded, 'Cambiar Ciudad', 'Caracas, Miranda'),
                        const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 64),
                        _buildMenuItem(Icons.grid_view_rounded, 'Explorar Categorías', 'Restaurantes, Parques...'),
                        const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 64),
                        _buildMenuItem(
                          Icons.bookmark_rounded, 
                          'Lugares Guardados', 
                          'Tus favoritos', 
                          onTapAction: () { 
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritosScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildCustomHeader(primaryText, primaryColor),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _selectedIndex,
              selectedItemColor: primaryColor,
              unselectedItemColor: const Color(0xFF9CA3AF),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedIndex = index;
                  _isMenuOpen = false;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Descubrir'),
                BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Rankings'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(Color primaryText, Color primaryColor) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 24, right: 24),
          color: Colors.white.withOpacity(0.85),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isMenuOpen ? const Color(0xFFEEF2FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: _isMenuOpen ? null : Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  child: Row(
                    children: [
                      Text('RankSpot', style: TextStyle(color: primaryText, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _isMenuOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF4B5563), size: 22),
                  onPressed: () => HapticFeedback.selectionClick(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTapAction}) {
    const Color primaryText = Color(0xFF111827);
    const Color primaryColor = Color(0xFF4F46E5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _toggleMenu();
          if (onTapAction != null) {
            Future.delayed(const Duration(milliseconds: 250), onTapAction);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: primaryText)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildBody() {
    if (_selectedIndex == 1) return const RankingsView(); 
    if (_selectedIndex == 2) return const ProfileView();

    const Color primaryText = Color(0xFF111827);
    const Color primaryColor = Color(0xFF4F46E5);

    return RefreshIndicator(
      color: primaryColor,
      backgroundColor: Colors.white,
      onRefresh: _cargarTopLugares,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 90), 
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '¿Qué quieres\ndescubrir hoy?',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.0, height: 1.15, color: primaryText),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Restaurantes, tiendas...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            SizedBox(
              height: 105,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categorias.length,
                itemBuilder: (context, index) {
                  return _buildCategoriaItem(_categorias[index]);
                },
              ),
            ),

            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Top de la semana',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: primaryText),
                  ),
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Ver todos', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            SizedBox(
              height: 295, 
              child: _isLoadingTop 
                ? _buildSkeletonCarrusel() 
                : _topLugares.isEmpty
                  ? const Center(child: Text('Aún no hay lugares calificados', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _topLugares.length,
                      itemBuilder: (context, index) {
                        final comercio = _topLugares[index];
                        return _buildLugarCard({
                          'id': comercio['id'],
                          'nombre': comercio['nombre'],
                          'categoria': comercio['categoria'],
                          'rating': double.tryParse(comercio['promedio']?.toString() ?? '0') ?? 0.0,
                          'reviews': comercio['total_votos'],
                          'imagen': (comercio['imagen'] != null && comercio['imagen'].toString().isNotEmpty) 
                              ? comercio['imagen'] 
                              : 'https://placehold.co/600x400/4F46E5/FFFFFF.png?text=${comercio['nombre'].toString().replaceAll(' ', '+')}',
                          'badge': index == 0 ? 'Top #1 🔥' : 'Top #${index + 1} ⭐',
                          'abierto': true
                        });
                      },
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  Widget _buildCategoriaItem(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RankingCategoriaScreen(
              categoria: cat['nombre'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                color: cat['color'],
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: cat['color'].withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(cat['icono'], color: cat['iconColor'], size: 30),
            ),
            const SizedBox(height: 10),
            Text(cat['nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563))),
          ],
        ),
      ),
    );
  }

  Widget _buildLugarCard(Map<String, dynamic> lugar) {
    const Color primaryText = Color(0xFF111827);
    final bool estaAbierto = lugar['abierto'] ?? true;
    final String heroTag = 'imagen-${lugar['nombre']}'; 

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(lugar: lugar, heroTag: heroTag),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 16, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Hero(
                    tag: heroTag, 
                    child: Image.network(
                      lugar['imagen'],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              lugar['badge'].split(' ').first,
                              style: const TextStyle(color: primaryText, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 👇 BOTÓN DE FAVORITOS (CONECTADO A RIVERPOD)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final favoritos = ref.watch(favoritosProvider);
                      final int comercioId = int.tryParse(lugar['id']?.toString() ?? '0') ?? 0;
                      final bool esFavorito = favoritos.contains(comercioId);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (comercioId != 0) {
                            ref.read(favoritosProvider.notifier).toggleFavorito(comercioId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key: ValueKey(esFavorito), 
                              color: esFavorito ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF), 
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lugar['nombre'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: primaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estaAbierto ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          estaAbierto ? 'Abierto' : 'Cerrado',
                          style: TextStyle(color: estaAbierto ? const Color(0xFF059669) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lugar['categoria'],
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        lugar['rating'].toString(),
                        style: const TextStyle(color: primaryText, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${lugar['reviews']})',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.delivery_dining_rounded, color: Color(0xFF4F46E5), size: 18),
                      const SizedBox(width: 4),
                      const Text('15-20 min', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 SKELETON LOADER PARA CUANDO CARGA LA BASE DE DATOS
  Widget _buildSkeletonCarrusel() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 270,
          margin: const EdgeInsets.only(right: 16, bottom: 12),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFF3F4F6),
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        );
      },
    );
  }
}