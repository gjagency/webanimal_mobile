import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';

class PetType {
  final String id;
  final String name;

  PetType({required this.id, required this.name});
}

class PostType {
  final String id;
  final String name;

  PostType({required this.id, required this.name});
}

class PostUser {
  final String id;
  final String username;
  final String fullName;
  final String? imageUrl;

  PostUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.imageUrl,
  });
}

class PostLocation {
  final String id;
  final double lat;
  final double lng;
  final String label;

  PostLocation({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
  });
}

class Post {
  final String id;
  final PostUser user;
  final PostType postType;
  final PetType petType;
  final String? imageUrl;
  final String description;
  final PostLocation location;
  final DateTime datetime;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.user,
    required this.postType,
    required this.petType,
    this.imageUrl,
    required this.description,
    required this.location,
    required this.datetime,
    this.likes = 0,
    this.comments = 0,
  });
}

class Comment {
  final String id;
  final String username;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.username,
    required this.text,
    required this.timestamp,
  });
}

class PostsService {
  // GET: Lista de posts
  static Future<List<Post>> getPosts({
    String? postType,
    String? petType,
    String? userId,
    double? lat,
    double? lng,
  }) async {
    final Map<String, String> queryParams = {};
    if (postType != null) queryParams['posteo_tipo'] = postType;
    if (petType != null) queryParams['mascota_tipo'] = petType;
    if (userId != null) queryParams['usuario'] = userId;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();

    final uri = Uri.parse(
      '${Config.baseUrl}/posteos/',
    ).replace(queryParameters: queryParams);

    final response = await AuthService.getWithToken(
      '/posteos/${uri.hasQuery ? "?${uri.query}" : ""}',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => _parsePost(json)).toList();
    }
    throw Exception('Error al cargar posts: ${response.statusCode}');
  }

  // GET: Post individual
  static Future<Post> getPost(String postId) async {
    final response = await AuthService.getWithToken('/posteos/$postId/');

    if (response.statusCode == 200) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al cargar post: ${response.statusCode}');
  }

  // POST: Crear post
  static Future<Post> createPost({
    required String postTypeId,
    required String petTypeId,
    required String description,
    required String imageBase64,
    required double lat,
    required double lng,
    required String locationLabel,
  }) async {
    final response = await AuthService.postWithToken('/posteos/', {
      'posteo_tipo': postTypeId,
      'mascota_tipo': petTypeId,
      'descripcion': description,
      'imagen': imageBase64,
      'ubicacion_lat': lat,
      'ubicacion_lng': lng,
      'ubicacion_label': locationLabel,
    });

    if (response.statusCode == 201) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al crear post: ${response.statusCode}');
  }

  // PUT: Actualizar post
  static Future<Post> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    final token = await AuthService.getAccessToken();
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/posteos/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar post: ${response.statusCode}');
  }

  // DELETE: Eliminar post
  static Future<bool> deletePost(String postId) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/posteos/$postId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // POST: Crear reacción
  static Future<bool> addReaction(String postId, String type) async {
    final response = await AuthService.postWithToken('/reacciones/', {
      'posteo': postId,
      'tipo': type,
    });

    return response.statusCode == 201;
  }

  // DELETE: Eliminar reacción
  static Future<bool> removeReaction(String reactionId) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/reacciones/$reactionId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<List<Comment>> getComments(String postId) async {
    final response = await AuthService.getWithToken(
      '/comentarios/?posteo=$postId',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map(
            (json) => Comment(
              id: json['id'].toString(),
              username: json['usuario']['username'],
              text: json['body'],
              timestamp: DateTime.parse(json['fecha_creacion']),
            ),
          )
          .toList();
    }
    throw Exception('Error al cargar comentarios');
  }

  // POST: Crear comentario
  static Future<bool> addComment(String postId, String text) async {
    final response = await AuthService.postWithToken('/comentarios/', {
      'posteo': postId,
      'body': text,
    });

    return response.statusCode == 201;
  }

  // GET: Tipos de mascotas
  static Future<List<PetType>> getPetTypes() async {
    final response = await AuthService.getWithToken('/mascotas/tipos/');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map(
            (json) => PetType(id: json['id'].toString(), name: json['nombre']),
          )
          .toList();
    }
    throw Exception('Error al cargar tipos de mascotas');
  }

  // GET: Tipos de posteos
  static Future<List<PostType>> getPostTypes() async {
    final response = await AuthService.getWithToken('/posteos/tipos/');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map(
            (json) => PostType(id: json['id'].toString(), name: json['nombre']),
          )
          .toList();
    }
    throw Exception('Error al cargar tipos de posteos');
  }

  // Parser privado
  static Post _parsePost(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      user: PostUser(
        id: json['usuario']['id'].toString(),
        username: json['usuario']['username'],
        fullName:
            json['usuario']['nombre_completo'] ?? json['usuario']['username'],
        imageUrl: json['usuario']['imagen'],
      ),
      postType: PostType(
        id: json['posteo_tipo']['id'].toString(),
        name: json['posteo_tipo']['nombre'],
      ),
      petType: PetType(
        id: json['mascota_tipo']['id'].toString(),
        name: json['mascota_tipo']['nombre'],
      ),
      imageUrl: json['imagen'],
      description: json['descripcion'],
      location: PostLocation(
        id: json['id'].toString(),
        lat: json['ubicacion_lat'],
        lng: json['ubicacion_lng'],
        label: json['ubicacion_label'],
      ),
      datetime: DateTime.parse(json['fecha_creacion']),
      likes: json['total_reacciones'] ?? 0,
      comments: json['total_comentarios'] ?? 0,
    );
  }
}
