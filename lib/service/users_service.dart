import 'dart:convert';

import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:http/http.dart' as http;

class AppVersion {
  final String androidVersionLatest;
  final String androidVersionMinimal;
  final String androidVersionUpdater;
  final String playStoreUrl;
  final String appStoreUrl;

  AppVersion({
    required this.androidVersionLatest,
    required this.androidVersionMinimal,
    required this.androidVersionUpdater,
    required this.playStoreUrl,
    required this.appStoreUrl,
  });

  factory AppVersion.fromJson(Map<String, dynamic> parsedJson) {
    return AppVersion(
      androidVersionLatest: parsedJson['android_version_latest'] ?? '',
      androidVersionMinimal: parsedJson['android_version_minimal'] ?? '',
      androidVersionUpdater: parsedJson['android_version_updater'] ?? '',
      playStoreUrl: parsedJson['play_store_url'] ?? '',
      appStoreUrl: parsedJson['app_store_url'] ?? '',
    );
  }
}

class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String? imageUrl;
  final bool esVeterinaria;
  final String? nombreComercial;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.nombreComercial,
    this.imageUrl,
    required this.esVeterinaria,
  });
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? image;

    final rawImage = json['avatar'] ?? json['imagen'];

    if (rawImage != null) {
      final img = rawImage.toString();

      if (img.startsWith('http://') || img.startsWith('https://')) {
        image = img;
      } else if (img.startsWith('/')) {
        image = '${Config.baseUrl}$img';
      }
    }

    return UserProfile(
      id: json['id'].toString(),
      username: json['username'],
      fullName: json['display_name'] ?? json['username'],
      imageUrl: image,
      esVeterinaria: json['es_veterinaria'] ?? false,
      nombreComercial: json['nombre_comercial'],
    );
  }

  String get displayName =>
      esVeterinaria ? (nombreComercial ?? fullName) : fullName;
}

class UserService {
  static Future<List<UserProfile>> searchUsers({
    String query = "",
    int take = 20,
    int skip = 0,
  }) async {
    final response = await AuthService.getWithToken(
      '/api/usuarios/?q=${Uri.encodeComponent(query)}',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List data = decoded is Map ? decoded['results'] ?? [] : decoded;

      return data
          .map<UserProfile>(
            (json) => UserProfile.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception('Error al buscar usuarios');
  }

  static Future<List<UserProfile>> getUsers({
    int take = 20,
    int skip = 0,
  }) async {
    final response = await AuthService.getWithToken(
      '/api/usuarios/?take=$take&skip=$skip',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List data = decoded is Map ? decoded['results'] ?? [] : decoded;

      return data
          .map<UserProfile>(
            (json) => UserProfile.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception('Error al cargar usuarios');
  }

  Future<AppVersion> appVersion() async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/app_version/'),
    );

    print("📡 STATUS: ${response.statusCode}");
    print("📦 BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Error al obtener versión (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    if (decoded['result'] == null) {
      throw Exception('La API no devolvió result');
    }

    return AppVersion.fromJson(decoded['result'] as Map<String, dynamic>);
  }
}
