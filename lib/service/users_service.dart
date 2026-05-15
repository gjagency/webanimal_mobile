import 'dart:convert';

import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';

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
  static Future<List<UserProfile>> searchUsers(String query) async {
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

  static Future<List<UserProfile>> getUsers() async {
    final response = await AuthService.getWithToken('/api/usuarios/');

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
}
