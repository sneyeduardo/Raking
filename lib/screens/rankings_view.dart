import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RankingsView extends StatefulWidget {
  const RankingsView({super.key});

  @override
  State<RankingsView> createState() => _RankingsViewState();
}

class _RankingsViewState extends State<RankingsView> {
  int _filtroSeleccionado = 0;
  final List<String> _filtros = ['Global', 'Restaurantes', 'Cafeterías', 'Deportes'];

  // Datos simulados.
  final List<Map<String, dynamic>> _podio = [
    {'nombre': 'Café Central', 'rating': 4.7, 'puesto': 2, 'color': const Color(0xFF94A3B8), 'imagen': 'https://placehold.co/400x400/4F46E5/FFFFFF.png?text=CC'}, // Plata (Slate)
    {'nombre': 'Burger Spot', 'rating': 4.9, 'puesto': 1, 'color': const Color(0xFFF59E0B), 'imagen': 'https://placehold.co/400x400/F59E0B/FFFFFF.png?text=BS'}, // Oro (Amber)
    {'nombre': 'Tech Store', 'rating': 4.5, 'puesto': 3, 'color': const Color(0xFFD97706), 'imagen': 'https://placehold.co/400x400/D97706/FFFFFF.png?text=TS'}, // Bronce
  ];

  final List<Map<String, dynamic>> _actividadReciente = [
    {'usuario': 'Sney P.', 'lugar': 'Burger Spot', 'rating': 5.0, 'tiempo': 'Hace 2 min'},
    {'usuario': 'Carlos M.', 'lugar': 'Tech Store', 'rating': 4.5, 'tiempo': 'Hace 15 min'},
    {'usuario': 'Ana G.', 'lugar': 'Café Central', 'rating': 5.0, 'tiempo': 'Hace 1 hora'},
  ];

  @override
  Widget build(BuildContext context) {
    // Paleta de colores principal
    const Color backgroundColor = Color(0xFFF9FAFB);
    const Color primaryText = Color(0xFF111827);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 32),
            
            // Encabezado principal
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Top Negocios',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                  color: primaryText,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Descubre los lugares mejor valorados',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Filtros tipo Píldora
            SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filtros.length,
                itemBuilder: (context, index) {
                  return _FilterPill(
                    texto: _filtros[index],
                    isSelected: _filtroSeleccionado == index,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _filtroSeleccionado = index);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 48),

            // El Podio Rediseñado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 280,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PodiumPillar(data: _podio[0], height: 140), // Plata
                    const SizedBox(width: 16),
                    _PodiumPillar(data: _podio[1], height: 180), // Oro
                    const SizedBox(width: 16),
                    _PodiumPillar(data: _podio[2], height: 110), // Bronce
                  ],
                ),
              ),
            ),

            const SizedBox(height: 56),

            // Sección de Actividad Reciente
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: -0.5, 
                  color: primaryText,
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _actividadReciente.length,
              itemBuilder: (context, index) {
                return _ActivityCard(actividad: _actividadReciente[index]);
              },
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// --- COMPONENTES EXTRAÍDOS ---

class _FilterPill extends StatelessWidget {
  final String texto;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({required this.texto, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5); // Indigo 600
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.3), 
              blurRadius: 12, 
              offset: const Offset(0, 4)
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), 
              blurRadius: 4, 
              offset: const Offset(0, 2)
            )
          ],
        ),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final Map<String, dynamic> data;
  final double height;

  const _PodiumPillar({required this.data, required this.height});

  @override
  Widget build(BuildContext context) {
    final bool isPrimero = data['puesto'] == 1;
    final Color rankColor = data['color'];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar y Corona
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: isPrimero ? 72 : 56,
              height: isPrimero ? 72 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: rankColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
                image: DecorationImage(image: NetworkImage(data['imagen']), fit: BoxFit.cover),
              ),
            ),
            if (isPrimero)
              Positioned(
                top: -20,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👑', style: TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Pilar
        Container(
          width: isPrimero ? 90 : 80,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: isPrimero ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [rankColor.withOpacity(0.15), Colors.white],
            ) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), 
                blurRadius: 10, 
                offset: const Offset(0, -4)
              ),
            ],
            border: Border(
              top: BorderSide(color: rankColor, width: 3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '${data['puesto']}',
                  style: TextStyle(
                    fontSize: isPrimero ? 32 : 24, 
                    fontWeight: FontWeight.w900, 
                    color: primaryText, // Asegúrate de definir primaryText o usar Color(0xFF111827)
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Fondo ambar muy claro
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      data['rating'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color get primaryText => const Color(0xFF111827);
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> actividad;

  const _ActivityCard({required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEEF2FF), // Fondo índigo muy claro
              child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), fontFamily: 'Roboto'),
                      children: [
                        TextSpan(
                          text: actividad['usuario'], 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))
                        ),
                        const TextSpan(text: ' calificó a '),
                        TextSpan(
                          text: actividad['lugar'], 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actividad['tiempo'], 
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    actividad['rating'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF92400E), 
                      fontWeight: FontWeight.w800, 
                      fontSize: 14
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}