import 'dart:convert';

import 'package:flutter/material.dart';
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
  final String color;
  final String icon;

  PostType({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

class City {
  final String id;
  final String ciudad;
  final String estado;
  final String pais;

  City({
    required this.id,
    required this.ciudad,
    required this.estado,
    required this.pais,
  });
}

class PostUser {
  final String id;
  final String username;
  final String fullName;
  final String? imageUrl;
  final bool esVeterinaria;
  final String? nombreComercial;

  PostUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.nombreComercial,
    this.imageUrl,
    required this.esVeterinaria,
  });
  factory PostUser.fromJson(Map<String, dynamic> json) {
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

  return PostUser(
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

class Promocion {
  final String id;
  final String titulo;
  final String descripcion;
  final String? precio;
  final String? imagen;
  final String? fechadesde;
  final String? fechahasta;
  final String nombreComercio;
  Promocion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.precio,
    this.imagen,
    this.fechadesde,
    this.fechahasta,
    required this.nombreComercio,
  });

factory Promocion.fromJson(Map<String, dynamic> json) {
  return Promocion(
    id: json['id'].toString(),
    titulo: json['titulo'] ?? '',
    descripcion: json['descripcion'] ?? '',
    precio: json['precio']?.toString(),
    imagen: json['imagen']?.toString(),
    fechadesde: json['fecha_desde']?.toString(),
    fechahasta: json['fecha_hasta']?.toString(),
    nombreComercio: json['nombreComercio'] ?? '',
  );
}

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
  final String? telefono;
  final PostLocation location;
  final DateTime datetime;
  final int likes;
  final int comments;
  final List<String> reacciones;

  Post({
    required this.id,
    required this.user,
    required this.postType,
    required this.petType,
    this.imageUrl,
    required this.description,
    this.telefono,
    required this.location,
    required this.datetime,
    this.likes = 0,
    this.comments = 0,
    this.reacciones = const [],
  });
}
class Comment {
  final String id;
  final String username;
  final String displayName;
  final String? avatar;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    String? avatar;

    final rawAvatar = json['usuario']?['avatar'];
    if (rawAvatar != null) {
      final img = rawAvatar.toString();
      if (img.startsWith('http://') || img.startsWith('https://')) {
        avatar = img;
      } else if (img.startsWith('/')) {
        avatar = '${Config.baseUrl}$img';
      }
    }

    final user = json['usuario'] ?? {};

    return Comment(
      id: json['id'].toString(),
      username: user['username'] ?? 'unknown',
      displayName: json['display_name'] ?? user['username'], // ✅ aquí usamos directamente el display_name del backend
      avatar: avatar,
      text: json['body'] ?? '',
      timestamp: DateTime.parse(json['fecha_creacion']),
    );
  }
}



class PostsService {
  // GET: Lista de posts
  static Future<List<Post>> getPosts({
    String? postType,
    String? petType,
    String? userId,
    String? esVeterinaria,
    String? vet,
    double? lat,
    double? lng,
    String? cityId,
  }) async {
    final Map<String, String> queryParams = {};
    if (postType != null) queryParams['posteo_tipo'] = postType;
    if (petType != null) queryParams['mascota_tipo'] = petType;
    if (esVeterinaria != null) queryParams['usuario__veterinaria'] = esVeterinaria;
    if (userId != null) queryParams['usuario'] = userId;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (cityId != null) queryParams['ciudad_id'] = cityId.toString();

    final uri = Uri.parse(
      '${Config.baseUrl}/api/posteos/',
    ).replace(queryParameters: queryParams);

    final response = await AuthService.getWithToken(
      '/api/posteos/${uri.hasQuery ? "?${uri.query}" : ""}',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => _parsePost(json)).toList();
    }
    throw Exception('Error al cargar posts: ${response.statusCode}');
  }

  // GET: Post individual
  static Future<Post> getPost(String postId) async {
    final response = await AuthService.getWithToken('/api/posteos/$postId/');

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
    required String telefono,
    required String imageBase64,
    required double lat,
    required double lng,
    required String locationLabel,
  }) async {
    final response = await AuthService.postWithToken('/api/posteos/', {
      'posteo_tipo': postTypeId,
      'mascota_tipo': petTypeId,
      'descripcion': description,
      'telefono': telefono,
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
      Uri.parse('${Config.baseUrl}/api/posteos/$postId/'),
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
      Uri.parse('${Config.baseUrl}/api/posteos/$postId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // POST: Crear reacción
  static Future<bool> addReaction(int postId, int typeId) async {
    final response = await AuthService.postWithToken(
      '/api/reacciones/',
      {
        'posteo': postId,
        'tipo': typeId,
      },
    );

    return response.statusCode == 201;
  }

  // DELETE: Eliminar reacción
  static Future<bool> removeReaction(String reactionId) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/reacciones/$reactionId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

static Future<List<Comment>> getComments(String postId) async {
  final response = await AuthService.getWithToken(
    '/api/comentarios/?posteo=$postId',
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);

    return data
        .map((json) => Comment.fromJson(json))
        .toList();
  }

  throw Exception('Error al cargar comentarios');
}



  // POST: Crear comentario
  static Future<bool> addComment(String postId, String text) async {
    final response = await AuthService.postWithToken('/api/comentarios/', {
      'posteo': postId,
      'body': text,
    });

    return response.statusCode == 201;
  }

  // GET: Tipos de mascotas
  static Future<List<PetType>> getPetTypes() async {
    final response = await AuthService.getWithToken('/api/mascotas/tipos/');

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
    final response = await AuthService.getWithToken('/api/posteos/tipos/');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map(
            (json) => PostType(
              id: json['id'].toString(),
              name: json['nombre'],
              color: json['color'],
              icon: json['icono'],
            ),
          )
          .toList();
    }
    throw Exception('Error al cargar tipos de posteos');
  }

  // Parser privado
static Post _parsePost(Map<String, dynamic> json) {
  final usuarioJson = json['usuario'] ?? {};

  return Post(
    id: json['id'].toString(),
    user: PostUser.fromJson(usuarioJson), // 👈 aquí usamos fromJson
    postType: PostType(
      id: json['posteo_tipo']['id'].toString(),
      name: json['posteo_tipo']['nombre'],
      color: json['posteo_tipo']['color'],
      icon: json['posteo_tipo']['icono'],
    ),
    petType: PetType(
      id: json['mascota_tipo']['id'].toString(),
      name: json['mascota_tipo']['nombre'],
    ),
    imageUrl: json['imagen'],
    description: json['descripcion'] ?? '',
    telefono: json['telefono'],
    location: PostLocation(
      id: json['id'].toString(),
      lat: (json['ubicacion_lat'] ?? 0).toDouble(),
      lng: (json['ubicacion_lng'] ?? 0).toDouble(),
      label: json['ubicacion_label'] ?? '',
    ),
    datetime: DateTime.parse(json['fecha_creacion']),
    likes: json['total_reacciones'] ?? 0,
    comments: json['total_comentarios'] ?? 0,
    reacciones: List<String>.from((json['reacciones'] ?? []).map((e) => e.toString())),
  );
}



  static Future<List<City>> searchCities(String query) async {
    final response = await AuthService.getWithToken(
      '/api/ciudades/?q=${Uri.encodeComponent(query)}&take=20',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results
          .map(
            (json) => City(
              id: json['id'],
              ciudad: json['ciudad'],
              estado: json['estado'],
              pais: json['pais'],
            ),
          )
          .toList();
    }
    throw Exception('Error al buscar ciudades');
  }
}
