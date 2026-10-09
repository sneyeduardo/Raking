import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ResenasModal extends StatefulWidget {
  final int comercioId;
  final String nombreComercio;

  const ResenasModal({super.key, required this.comercioId, required this.nombreComercio});

  // Método estático para mostrar el modal fácilmente desde cualquier pantalla
  static void mostrar(BuildContext context, int comercioId, String nombreComercio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResenasModal(comercioId: comercioId, nombreComercio: nombreComercio),
    );
  }

  @override
  State<ResenasModal> createState() => _ResenasModalState();
}

class _ResenasModalState extends State<ResenasModal> {
  List<dynamic> _resenas = [];
  bool _isLoading = true;
  bool _isPublishing = false;
  final TextEditingController _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarResenas();
  }

  Future<void> _cargarResenas() async {
    final resenas = await ApiService.obtenerResenas(widget.comercioId);
    if (mounted) {
      setState(() {
        _resenas = resenas;
        _isLoading = false;
      });
    }
  }

  Future<void> _publicar() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _isPublishing = true);
    HapticFeedback.mediumImpact();

    final exito = await ApiService.publicarResena(widget.comercioId, texto);
    
    if (mounted) {
      setState(() => _isPublishing = false);
      if (exito) {
        _comentarioController.clear();
        _cargarResenas(); // Recargamos para mostrar el nuevo comentario
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al publicar. Inicia sesión para comentar.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom; // Para empujar el input cuando sale el teclado

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Barrita superior de arrastre
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Reseñas de ${widget.nombreComercio}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),

          // Lista de Comentarios
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : _resenas.isEmpty
                ? const Center(child: Text('Aún no hay reseñas.\n¡Sé el primero en opinar!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500)))
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _resenas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final resena = _resenas[index];
                      // Formatear la fecha básica
                      final fechaStr = resena['fecha'].toString().split('T')[0];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF3F4F6))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${resena['nombre']} ${resena['apellido']}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                                Text(fechaStr, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(resena['comentario'], style: const TextStyle(color: Color(0xFF4B5563), height: 1.4)),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Campo para escribir (Fijado abajo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentarioController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu reseña...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isPublishing ? null : _publicar,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                    child: _isPublishing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}