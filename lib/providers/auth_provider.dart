import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// 1. Definimos cómo se ve nuestro "Estado"
class AuthState {
  final Map<String, dynamic>? usuario;
  final bool isLoading;

  AuthState({this.usuario, this.isLoading = false});

  // Copia el estado actualizando solo lo que necesitemos
  AuthState copyWith({Map<String, dynamic>? usuario, bool? isLoading}) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. Creamos el Notificador (El cerebro que controla el estado)
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()); // Inicia sin usuario y sin cargar

  Future<bool> login(String correo, String password) async {
    state = state.copyWith(isLoading: true); // Muestra el loading automático
    
    final resultado = await ApiService.login(correo, password);
    
    if (resultado != null) {
      // Login exitoso: Guardamos el usuario en el estado general
      state = AuthState(usuario: resultado['usuario'], isLoading: false);
      return true;
    }
    
    // Login fallido
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await ApiService.logout(); // Destruye el token del teléfono
    state = AuthState(usuario: null, isLoading: false); // Borra el usuario de la memoria
  }
}

// 3. Este es el Proveedor Global que usaremos en toda la app
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});