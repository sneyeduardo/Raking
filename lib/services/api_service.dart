import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class ApiService {
  // ATENCIÓN: Cambia esta IP por tu dominio o IP del servidor cuando pases a producción
  static const String baseUrl = 'http://26.59.102.18:3000';
  
  // Bóveda segura para guardar el Token JWT
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // --- MÉTODOS DE AUTENTICACIÓN ---

  static Future<Map<String, dynamic>?> login(String correo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 1. Extraemos el token y el usuario
        final token = data['token'];
        final usuario = data['usuario'];

        // 2. Guardamos el token en la bóveda segura del teléfono
        await _storage.write(key: _tokenKey, value: token);

        return {'usuario': usuario};
      }
      return null;
    } catch (e) {
      debugPrint('Error en login: $e');
      return null;
    }
  }
  // --- MÉTODOS DE RESEÑAS ---

  static Future<List<dynamic>> obtenerResenas(int comercioId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/comercios/resenas/$comercioId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo reseñas: $e');
      return [];
    }
  }

  static Future<bool> publicarResena(int comercioId, String comentario) async {
    try {
      final headers = await _getAuthHeaders(); // Usamos token porque requiere inicio de sesión
      final response = await http.post(
        Uri.parse('$baseUrl/api/comercios/resenas'),
        headers: headers,
        body: jsonEncode({
          'comercio_id': comercioId,
          'comentario': comentario,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error publicando reseña: $e');
      return false;
    }
  }

  static Future<bool?> toggleFavorito(int comercioId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/comercios/favoritos/toggle'),
        headers: headers,
        body: jsonEncode({'comercio_id': comercioId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite']; // Retorna true si se añadió, false si se quitó
      }
      return null;
    } catch (e) {
      debugPrint('Error en toggle favorito: $e');
      return null;
    }
  }

  static Future<List<dynamic>> obtenerTopComercios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/comercios/top'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo top comercios: $e');
      return [];
    }
  }

  static Future<List<dynamic>> obtenerFavoritos() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/comercios/favoritos'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  } 

  static Future<bool> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'correo': correo,
          'telefono': telefono,
          'password': password,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error en registro: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    // Borramos el token del teléfono de forma segura
    await _storage.delete(key: _tokenKey);
    AuthService.usuarioActual = null;
  }

  static Future<bool> restablecerContrasena(String token, String nuevaPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'nuevaPassword': nuevaPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- MÉTODOS PROTEGIDOS (Requieren Token) ---

  // Método auxiliar para obtener los headers con el Token inyectado
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> enviarCalificacion({required String qrData, required int rating}) async {
    try {
      // Usamos _getAuthHeaders() para enviar el Token al servidor
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/comercios/votar'),
        headers: headers,
        body: jsonEncode({
          'nfc_codigo': qrData,
          'rating': rating,
        }),
      );

      // 200 = Éxito. 400 = Ya votó (puedes manejar este error específicamente en la UI luego)
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error enviando calificación: $e');
      return false;
    }
  }

  // --- MÉTODOS PÚBLICOS DE COMERCIOS ---

  static Future<bool> registrarEmpresa({
    required String nombre, 
    required String categoria, 
    required String nfcCodigo
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/comercios/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'categoria': categoria,
          'nfc_codigo': nfcCodigo,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> obtenerComerciosPorCategoria(String categoria) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/comercios/categoria/$categoria'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo comercios: $e');
      return [];
    }
  }
}