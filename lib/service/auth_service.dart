import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración fija
class Config {
  static const String baseUrl = 'http://127.0.0.1:8000';
}

class AuthService {
  static const _tokenKey = 'token';

  /// Login robusto
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Login response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token != null && token.toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
          return true;
        } else {
          print('Login failed: no token returned');
          return false;
        }
      } else {
        print('Login failed: status code ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Login exception: $e');
      return false;
    }
  }

  /// Obtener token guardado
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('SharedPreferences not initialized: $e');
      return null;
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${Config.baseUrl}/logout/'),
          headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('Logout error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Error removing token: $e');
    }
  }

  /// Revisar si hay sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// GET con token
  static Future<http.Response> getWithToken(String path) async {
    final token = await getToken();
    return http.get(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
  }

  /// POST con token
  static Future<http.Response> postWithToken(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    return http.post(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}
