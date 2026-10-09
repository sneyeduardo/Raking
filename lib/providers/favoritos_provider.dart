import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// El estado será una lista de IDs de comercios que el usuario tiene en favoritos (Ej: [1, 5, 12])
class FavoritosNotifier extends StateNotifier<List<int>> {
  FavoritosNotifier() : super([]);

  // Cargar los favoritos al iniciar sesión
  Future<void> cargarFavoritos() async {
    final favoritosData = await ApiService.obtenerFavoritos();
    state = favoritosData.map<int>((comercio) => comercio['id'] as int).toList();
  }

  // Hacer el toggle visual instantáneo (Optimistic UI)
  Future<void> toggleFavorito(int comercioId) async {
    final estadoAnterior = state;
    
    // 1. Actualizamos la UI al instante para que se sienta súper rápido
    if (state.contains(comercioId)) {
      state = state.where((id) => id != comercioId).toList();
    } else {
      state = [...state, comercioId];
    }

    // 2. Enviamos al servidor
    final resultado = await ApiService.toggleFavorito(comercioId);
    
    // 3. Si hubo un error de red, revertimos visualmente al estado anterior
    if (resultado == null) {
      state = estadoAnterior;
    }
  }

  // Limpiar al cerrar sesión
  void limpiarFavoritos() {
    state = [];
  }
}

final favoritosProvider = StateNotifierProvider<FavoritosNotifier, List<int>>((ref) {
  return FavoritosNotifier();
});