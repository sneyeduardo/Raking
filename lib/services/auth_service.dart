class AuthService {
  static Map<String, dynamic>? usuarioActual;

  static bool get esAdmin {
    if (usuarioActual == null) return false;
    return usuarioActual!['rol'] == 'admin';
  }
}