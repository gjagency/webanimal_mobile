import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Se lanza cuando el login es correcto pero la cuenta todavía
/// no fue activada por un admin (ej: veterinaria/comercio en alta).
class AccountPendingException implements Exception {
  final String message;
  AccountPendingException(this.message);

  @override
  String toString() => message;
}

/// Servicio de autenticación
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static String? get avatarUrl => _currentUser?['avatar'];
  static String? get currentUserId => _currentUser?['id']?.toString();
  static String get displayNameSafe => displayName;
  static Map<String, dynamic>? _currentUser;
  static Map<String, dynamic>? get currentUser => _currentUser;

  /// 🔴 ESTE CLIENT ID TIENE QUE SER EL WEB CLIENT
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '472691331964-c55775j6obsbcnugcfo4ac6d9nsf2s6r.apps.googleusercontent.com',
    clientId:
        '472691331964-v39lrtmpoddaidmr719f9a2nf9nfi9ik.apps.googleusercontent.com',
  );

  /// 👤 PERFIL DE OTRO USUARIO POR ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await getWithToken('/api/users/$userId/');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      debugPrint('Error getUserById: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Exception getUserById: $e');
      return null;
    }
  }

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

      return false;
    }

    // 🔒 Cuenta correcta pero todavía no activada por un admin,
    // u otro error específico enviado por el backend.
    String message = 'Usuario o contraseña incorrectos';
    String? code;
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data['message'] != null) message = data['message'];
        code = data['code'];
      }
    } catch (_) {}

    if (code == 'account_pending') {
      throw AccountPendingException(message);
    }

    throw Exception(message);
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
     LOGIN CON GOOGLE
     ========================================================== */
  static Future<bool> loginWithGoogle() async {
    try {
      // 🔁 Fuerza que se muestre el selector de cuentas siempre,
      // en vez de reusar en silencio la última sesión de Google cacheada.
      await _googleSignIn.signOut();

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

        return false;
      }

      String message = 'No se pudo iniciar sesión con Google';
      String? code;
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          if (data['message'] != null) message = data['message'];
          code = data['code'];
        }
      } catch (_) {}

      if (code == 'account_pending') {
        throw AccountPendingException(message);
      }

      return false;
    } on AccountPendingException {
      rethrow;
    } catch (e) {
      debugPrint('Google login exception: $e');
      return false;
    }
  }

  /* ==========================================================
     OBTENER ID TOKEN DE GOOGLE (sin loguear)
     Se usa para registrar una veterinaria/comercio nueva.
     ========================================================== */
  static Future<String?> getGoogleIdToken() async {
    try {
      // 🔁 Fuerza el selector de cuentas en vez de reusar una sesión cacheada.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in cancelado');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      return googleAuth.idToken;
    } catch (e) {
      debugPrint('getGoogleIdToken error: $e');
      return null;
    }
  }

  /* ==========================================================
     REGISTRAR VETERINARIA/COMERCIO CON GOOGLE
     ========================================================== */
  static Future<bool> registerVeterinariaConGoogle({
    required String idToken,
    required String nombreComercial,
    String tipoNegocio = 'veterinaria',
    String? telefono,
    String? direccion,
    String? ubicacionLabel,
    double? lat,
    double? lng,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/register-vet-google/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'nombre_comercial': nombreComercial,
        'tipo_negocio': tipoNegocio,
        'telefono': telefono ?? '',
        'direccion': direccion ?? '',
        'ubicacion_label': ubicacionLabel ?? '',
        'ubicacion_lat': lat,
        'ubicacion_lng': lng,
      }),
    );

    debugPrint(
      'Register vet google response: ${response.statusCode} ${response.body}',
    );

    if (response.statusCode == 201) {
      return true;
    }

    String message = 'Error al registrar el comercio';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) message = data['message'];
    } catch (_) {}

    throw Exception(message);
  }

  /* ==========================================================
     LOGIN CON APPLE
     ========================================================== */
  static Future<dynamic> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'app.eco.agency.gj.webanimal',
          redirectUri: Uri.parse(
            'https://webanimal.com/api/auth/apple/callback',
          ),
        ),
      );

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/auth/apple/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': credential.identityToken,
          'email': credential.email,
          'first_name': credential.givenName,
          'last_name': credential.familyName,
          'apple_user_id': credential.userIdentifier,
          'authorization_code': credential.authorizationCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final access = data['access'];
        final refresh = data['refresh'];

        if (access != null && refresh != null) {
          await _saveTokens(access, refresh);
          return true;
        }

        return false;
      }

      String message = 'No se pudo iniciar sesión con Apple';
      String? code;
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          if (data['message'] != null) message = data['message'];
          code = data['code'];
        }
      } catch (_) {}

      if (code == 'account_pending') {
        throw AccountPendingException(message);
      }

      return false;
    } on AccountPendingException {
      rethrow;
    } catch (e) {
      debugPrint('Apple login exception: $e');
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

    return esVeterinaria ? (nombreComercial ?? fullName) : fullName;
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
    String tipoNegocio = 'veterinaria',
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
      request.fields['tipo_negocio'] = tipoNegocio;
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        /// 🔥 GUARDAMOS EL USUARIO GLOBAL
        _currentUser = data;

        debugPrint('👤 PROFILE LOADED');
        debugPrint('ID: ${data['id']}');
        debugPrint('NAME: ${data['display_name']}');
        debugPrint('AVATAR: ${data['avatar']}');
        debugPrint('VET: ${data['es_veterinaria']}');

        return data;
      }

      debugPrint(
        'Error al obtener perfil: ${response.statusCode} ${response.body}',
      );
      return {};
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
      final response = await getWithToken('/veterinarias/promociones/mias/');

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

  static Future<List<Map<String, dynamic>>> getOfertasPromociones() async {
    try {
      final response = await getWithToken(
        '/api/veterinarias/promociones/ofertas/',
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint(
          'Error al obtener ofertas de promociones: ${response.statusCode} ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Excepción en getOfertasPromociones: $e');
      return [];
    }
  }

  static Future<bool> updateProfile({
    required String name,
    required String lastName,
    required String email,
    required String bio,
    required String? avatarId,
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

      if (avatarId != null) {
        request.fields['avatar_id'] = avatarId;
      }

      final response = await request.send();
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
    String? imagenId,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) {
        print('No hay token disponible, usuario no logueado');
        return false;
      }

      final uri = Uri.parse(
        '${Config.baseUrl}/api/veterinarias/promociones/cargar/',
      );
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['titulo'] = titulo;
      request.fields['descripcion'] = descripcion;
      if (precio != null) request.fields['precio'] = precio;
      if (imagenId != null) request.fields['media_id'] = imagenId;

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

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 401) {
        return false;
      }

      final Map<String, dynamic> jsonResponse = json.decode(responseBody);
      return jsonResponse['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> eliminarPromocion(String promocionId) async {
    try {
      final response = await AuthService.deleteWithToken(
        '/api/veterinarias/promociones/$promocionId/eliminar/',
        {},
      );

      if (response.statusCode != 200) return false;

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['ok'] == true;
    } catch (e) {
      return false;
    }
  }
}
