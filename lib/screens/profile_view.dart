import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Importamos Riverpod
import 'dart:ui';
import '../providers/auth_provider.dart'; // 👈 Importamos nuestro Provider
import 'agregar_empresa_screen.dart';
import '../providers/favoritos_provider.dart';
// 1. Cambiamos StatelessWidget por ConsumerWidget
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  // 2. Agregamos el WidgetRef para poder leer el estado
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Escuchamos al proveedor en tiempo real
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    
    final bool esAdmin = usuario != null && usuario['rol'] == 'admin';
    final String nombreCompleto = usuario != null ? '${usuario['nombre']} ${usuario['apellido']}' : 'Usuario';
    final String correo = usuario != null ? usuario['correo'] : 'correo@example.com';

    // ... (el resto de tus colores y diseño se mantiene igual)

    const Color primaryText = Color(0xFF111827);
    const Color primaryColor = Color(0xFF4F46E5);
    const Color secondaryText = Color(0xFF6B7280);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Espaciado para respetar el AppBar transparente
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 24),
          
          // Título alineado a la izquierda
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mi Perfil',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: primaryText,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // Foto de perfil con anillo eíndigo elegante
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFEEF2FF),
              backgroundImage: NetworkImage('https://placehold.co/400x400/4F46E5/FFFFFF.png?text=SP'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nombre y correo dinámicos
          Text(
            nombreCompleto,
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w800, 
              color: primaryText, 
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            correo,
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500, 
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 40),

          // Tarjeta de opciones estilo Light Card con sombra sutil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🏢 OPCIÓN DE ADMIN (Solo aparece si AuthService.esAdmin es true)
                  if (esAdmin) ...[
                    _buildOptionRow(
                      icon: Icons.add_business_rounded, 
                      title: 'Agregar empresa',   
                      iconColor: primaryColor,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AgregarEmpresaScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 60),
                  ],

                  _buildOptionRow(
                    icon: Icons.person_outline_rounded, 
                    title: 'Administrar perfil', 
                    iconColor: primaryColor,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 60),
                  _buildOptionRow(
                    icon: Icons.headset_mic_outlined, 
                    title: 'Contáctanos', 
                    iconColor: primaryColor,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 60),
                  _buildOptionRow(
  icon: Icons.logout_rounded, 
  title: 'Cerrar sesión', 
  iconColor: Colors.redAccent,
  isDestructive: true,
  onTap: () async {
    HapticFeedback.mediumImpact();

    // 👇 Vaciamos la lista de favoritos de Riverpod
    ref.read(favoritosProvider.notifier).limpiarFavoritos();
    
    // 👈 Le decimos a Riverpod que ejecute el logout
    await ref.read(authProvider.notifier).logout(); 
    
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  },
),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon, 
    required String title, 
    required Color iconColor, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    const Color primaryText = Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w600, 
                    color: isDestructive ? Colors.redAccent : primaryText,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded, 
                color: isDestructive ? Colors.transparent : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}