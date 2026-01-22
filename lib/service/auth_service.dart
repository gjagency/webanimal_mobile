import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static String? get avatarUrl => _currentUser?['avatar'];
  static String get displayNameSafe => displayName;
  static Map<String, dynamic>? _currentUser;
  static Map<String, dynamic>? get currentUser => _currentUser;

  /// 🔴 ESTE CLIENT ID TIENE QUE SER EL WEB CLIENT
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '824173925704-911j6uatk6hqj9rsv07dr4opud7ar4kl.apps.googleusercontent.com',
  );

  static Future<void> loadCurrentUser() async {
    try {
      final profile = await getProfile();
      if (profile.isNotEmpty) {
        _currentUser = profile;
        debugPrint('🧠 Usuario logueado: ${profile['first_name']}');
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
    }
  }

  static String? get username => _currentUser?['first_name'];
  static bool get esVeterinaria => _currentUser?['es_veterinaria'] == true;

  /* ==========================================================
     LOGIN USUARIO / PASSWORD (JWT)
     ========================================================== */
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/auth/login/'),
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
  static Future<bool> recoverPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/auth/reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      debugPrint(
        'Recover password response: ${response.statusCode} ${response.body}',
      );

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
        Uri.parse('${Config.baseUrl}/api/auth/reset/confirm/'),
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
   TODAS LAS OFERTAS / PROMOCIONES ACTIVAS
   ========================================================== */
static Future<List<Map<String, dynamic>>> getOfertasPromociones() async {
  try {
    final response = await getWithToken('/api/veterinarias/promociones/ofertas/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      debugPrint('Error al obtener ofertas: ${response.statusCode} ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('Excepción en getOfertasPromociones: $e');
    return [];
  }
}


  /* ==========================================================
     LOGIN CON GOOGLE
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
        Uri.parse('${Config.baseUrl}/api/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': googleAuth.idToken}),
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
static String get displayName {
  final user = _currentUser;
  if (user == null) return '';

  final bool esVeterinaria = user['es_veterinaria'] == true;

  final String fullName =
      ('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}')
              .trim()
              .isNotEmpty
          ? '${user['first_name']} ${user['last_name']}'.trim()
          : user['username'] ?? '';

  final String? nombreComercial = user['nombre_comercial'];

  return esVeterinaria
      ? (nombreComercial ?? fullName)
      : fullName;
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
      await postWithToken("api/logout/", {});
    } catch (_) {}

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

  static Future<http.Response> putWithToken(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await getAccessToken();

    return http.put(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteWithToken(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await getAccessToken();

    return http.delete(
      Uri.parse('${Config.baseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }


static Future<bool> registerVeterinaria({
  required String email,
  required String password,
  required String nombreComercial,
  String? telefono,
  String? direccion,
  File? imagen,
  String? ubicacionLabel,
  double? lat,
  double? lng,
}) async {
  try {
    final uri = Uri.parse('${Config.baseUrl}/auth/register-vet/');
    final request = http.MultipartRequest('POST', uri);

    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['nombre_comercial'] = nombreComercial;
    request.fields['telefono'] = telefono ?? '';
    request.fields['direccion'] = direccion ?? '';
    request.fields['ubicacion_label'] = ubicacionLabel ?? '';
    request.fields['ubicacion_lat'] = lat?.toString() ?? '';
    request.fields['ubicacion_lng'] = lng?.toString() ?? '';

    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'imagen',
          imagen.path,
          filename: imagen.path.split('/').last,
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    debugPrint(
      'Register vet response: ${streamedResponse.statusCode} $responseBody',
    );

    if (streamedResponse.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(responseBody);
      final message = data['message'] ?? 'Error al registrar veterinaria';
      throw Exception(message);
    }
  } catch (e) {
    debugPrint('Register vet error: $e');
    return false;
  }
}


  /* ==========================================================
     GET PROFILE
     ========================================================== */
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await getWithToken('/api/auth/profile/');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
          'Error al obtener perfil: ${response.statusCode} ${response.body}',
        );
        return {};
      }
    } catch (e) {
      debugPrint('Excepción en getProfile: $e');
      return {};
    }
  }
/* ==========================================================
   PROMOCIONES DE MI VETERINARIA
   ========================================================== */
static Future<List<Map<String, dynamic>>> getMisPromociones() async {
  try {
    final response = await getWithToken(
      '/veterinarias/promociones/mias/',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      debugPrint(
        'Error al obtener promociones: ${response.statusCode} ${response.body}',
      );
      return [];
    }
  } catch (e) {
    debugPrint('Excepción en getMisPromociones: $e');
    return [];
  }
}

  static Future<bool> updateProfile({
    required String name,
    required String lastName,
    required String email,
    required String bio,
    File? avatar,
  }) async {
    try {
      final token = await getAccessToken();

      final uri = Uri.parse('${Config.baseUrl}/api/auth/profile/');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['last_name'] = lastName;
      request.fields['email'] = email;
      request.fields['bio'] = bio;

      if (avatar != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', avatar.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Update profile response: ${response.statusCode}');
      debugPrint(responseBody);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updateProfile: $e');
      return false;
    }
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await postWithToken('/api/auth/change-password/', {
      'old_password': currentPassword,
      'new_password': newPassword,
    });

    return response.statusCode == 200;
  }
  
}


class PromocionesService {
  static Future<bool> crearPromocion({
    required String titulo,
    required String descripcion,
    String? precio,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    File? imagen,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      final uri = Uri.parse('${Config.baseUrl}/api/veterinarias/promociones/cargar/');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['titulo'] = titulo;
      request.fields['descripcion'] = descripcion;

      if (precio != null) request.fields['precio'] = precio;

      if (fechaDesde != null) {
        request.fields['fecha_desde'] =
            "${fechaDesde.year.toString().padLeft(4, '0')}-"
            "${fechaDesde.month.toString().padLeft(2, '0')}-"
            "${fechaDesde.day.toString().padLeft(2, '0')}";
      }
      if (fechaHasta != null) {
        request.fields['fecha_hasta'] =
            "${fechaHasta.year.toString().padLeft(4, '0')}-"
            "${fechaHasta.month.toString().padLeft(2, '0')}-"
            "${fechaHasta.day.toString().padLeft(2, '0')}";
      }

      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'imagen',
            imagen.path,
            filename: imagen.path.split('/').last,
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // 🔹 Parseamos el JSON de la respuesta
      final Map<String, dynamic> jsonResponse = json.decode(responseBody);

      // 🔹 Devuelve true si la API dice ok = true, false en cualquier otro caso
      return jsonResponse['ok'] == true;
    } catch (e) {
      print('Excepción creando promoción: $e');
      return false;
    }
  }
}
