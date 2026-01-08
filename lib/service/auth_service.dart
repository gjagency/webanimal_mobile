import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// 🔴 ESTE CLIENT ID TIENE QUE SER EL WEB CLIENT
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '824173925704-911j6uatk6hqj9rsv07dr4opud7ar4kl.apps.googleusercontent.com',
  );

  /* ==========================================================
     LOGIN USUARIO / PASSWORD (JWT)
     ========================================================== */
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      debugPrint('Login response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final access = data['access'];
        final refresh = data['refresh'];

        if (access != null && refresh != null) {
          await _saveTokens(access, refresh);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login exception: ${e.toString()}');
      return false;
    }
  }

  /* ==========================================================
     RECOVER PASSWORD
     ========================================================== */
  /* ==========================================================
   RECOVER PASSWORD (CORREGIDO)
   ========================================================== */
  static Future<bool> recoverPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/reset/'), // ✅ CORRECTO
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      debugPrint(
        'Recover password response: ${response.statusCode} ${response.body}',
      );

      // Django devuelve 200 aunque el email no exista (correcto)
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Recover password error: $e');
      return false;
    }
  }

  /* ==========================================================
   CONFIRM RESET PASSWORD
   ========================================================== */
  static Future<bool> confirmResetPassword({
    required String uid,
    required String token,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/reset/confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'token': token, 'password': password}),
      );

      debugPrint(
        'Confirm reset response: ${response.statusCode} ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Confirm reset password error: $e');
      return false;
    }
  }

  /* ==========================================================
     LOGIN CON GOOGLE (CORREGIDO)
     ========================================================== */
  static Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google login cancelado');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('ID TOKEN ES NULL');
        return false;
      }

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': googleAuth.idToken, // 🔥 JWT REAL
        }),
      );
      debugPrint('ID TOKEN: ${googleAuth.idToken}');

      debugPrint(
        'Google login response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final access = data['access'];
        final refresh = data['refresh'];

        if (access != null && refresh != null) {
          await _saveTokens(access, refresh);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Google login exception: $e');
      return false;
    }
  }

  /* ==========================================================
     TOKEN MANAGEMENT
     ========================================================== */
  static Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /* ==========================================================
     LOGOUT
     ========================================================== */
  static Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /* ==========================================================
     REQUESTS CON JWT
     ========================================================== */
  static Future<http.Response> getWithToken(String path) async {
    final token = await getAccessToken();

    return http.get(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<http.Response> postWithToken(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await getAccessToken();

    return http.post(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}
