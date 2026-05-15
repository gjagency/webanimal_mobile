import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';
import 'package:mobile_app/service/users_service.dart';

class PetType {
  final String id;
  final String name;

  PetType({required this.id, required this.name});

  factory PetType.fromJson(Map<String, dynamic> json) {
    return PetType(
      id: json['id'].toString(),
      name: json['nombre'] ?? json['name'] ?? '',
    );
  }
}

class PostType {
  final String id;
  final String name;
  final String? color;
  final String? icon;

  PostType({required this.id, required this.name, this.color, this.icon});

  factory PostType.fromJson(Map<String, dynamic> json) {
    return PostType(
      id: json['id'].toString(),
      name: json['nombre'] ?? json['name'] ?? '',
      color: json['color'],
      icon: json['icono'] ?? json['icon'],
    );
  }
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

class PromocionesPorVeterinaria {
  final int veterinariaId;
  final String nombreComercio;
  final String? avatar;
  final List<Promocion> promociones;
  final int userId;

  PromocionesPorVeterinaria({
    required this.veterinariaId,
    required this.nombreComercio,
    required this.promociones,
    this.avatar,
    required this.userId,
  });

  factory PromocionesPorVeterinaria.fromJson(Map<String, dynamic> json) {
    return PromocionesPorVeterinaria(
      veterinariaId: json['veterinaria_id'],
      nombreComercio: json['nombreComercio'],
      avatar: json['avatar'],
      userId: json['user_id'],
      promociones: (json['promociones'] as List)
          .map((e) => Promocion.fromJson(e))
          .toList(),
    );
  }
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
  final int veterinariaId;
  Promocion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.precio,
    this.imagen,
    this.fechadesde,
    this.fechahasta,
    required this.nombreComercio,
    required this.veterinariaId,
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
      veterinariaId: json['veterinaria_id'],
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

class PostMedia {
  final String id;
  final String url;
  final String mimeType;
  final String filename;

  PostMedia({
    required this.id,
    required this.url,
    required this.mimeType,
    required this.filename,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'].toString(),
      url: (json['url'] ?? '').toString(),
      mimeType: (json['mime_type'] ?? '').toString().toLowerCase(),
      filename: (json['filename'] ?? '').toString(),
    );
  }

  bool get isVideo => mimeType.startsWith('video/');
  bool get isImage => mimeType.startsWith('image/');
}

class Post {
  final String id;
  final UserProfile user;
  final PostType postType;
  final PetType petType;
  final List<PostMedia> medias;
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
    required this.description,
    this.telefono,
    required this.location,
    required this.datetime,
    this.likes = 0,
    this.comments = 0,
    this.reacciones = const [],
    this.medias = const [],
  });
}

class Comment {
  final String id;
  final String? userId;
  final String username;
  final String displayName;
  final String? avatar;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
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
      userId: json['user_id']?.toString(),
      username: user['username'] ?? 'unknown',
      displayName:
          json['display_name'] ??
          user['username'], // ✅ aquí usamos directamente el display_name del backend
      avatar: avatar,
      text: json['body'] ?? '',
      timestamp: DateTime.parse(json['fecha_creacion']),
    );
  }
}

class PostsService {
  // POSTS GET
  static Future<List<Post>> getPosts({
    String? postType,
    String? petType,
    String? userId,
    String? esVeterinaria,
    String? vet,
    double? lat,
    double? lng,
    String? cityId,
    int page = 1,
  }) async {
    final Map<String, String> queryParams = {};

    if (postType != null) queryParams['posteo_tipo'] = postType;
    if (petType != null) queryParams['mascota_tipo'] = petType;
    if (esVeterinaria != null) {
      queryParams['usuario__veterinaria'] = esVeterinaria;
    }
    if (userId != null) queryParams['usuario'] = userId;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (cityId != null) queryParams['ciudad_id'] = cityId;
    queryParams['page'] = page.toString();

    // 🔥 paginación
    queryParams['page'] = page.toString();

    final uri = Uri.parse(
      '${Config.baseUrl}/api/posteos/',
    ).replace(queryParameters: queryParams);

    final response = await AuthService.getWithToken(
      '/api/posteos/${uri.hasQuery ? "?${uri.query}" : ""}',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // si django devuelve paginado
      final List data = decoded is Map ? decoded['results'] : decoded;

      return data.map<Post>((json) => _parsePost(json)).toList();
    }

    throw Exception('Error al cargar posts: ${response.statusCode}');
  }

  static Future<List<Post>> getPostsByUser(String userId) async {
    final response = await AuthService.getWithToken(
      '/api/posteos/?usuario=$userId',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => _parsePost(e)).toList(); // ✅ usar TU parser real
    }

    throw Exception('Error cargando posts del usuario: ${response.statusCode}');
  }

  static Future<List<Post>> getMisPosts() async {
    final token = await AuthService.getAccessToken();
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/mis_posteos/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // 🔹 Usar _parsePost en lugar de fromJson
      return data.map((e) => _parsePost(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('No autorizado. Verifica tu sesión.');
    } else {
      throw Exception('Error al obtener mis posts: ${response.statusCode}');
    }
  }

  static Future<Post> getPost(String postId) async {
    final response = await AuthService.getWithToken('/api/posteos/$postId/');

    if (response.statusCode == 200) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al cargar post: ${response.statusCode}');
  }

  // POST EDIT

  static Future<Post> createPost({
    required String postTypeId,
    required String petTypeId,
    required String description,
    required String telefono,
    required List<String> mediaIds,
    required double lat,
    required double lng,
    required String locationLabel,
  }) async {
    final response = await AuthService.postWithToken('/api/posteos/', {
      'posteo_tipo': postTypeId,
      'mascota_tipo': petTypeId,
      'descripcion': description,
      'telefono': telefono,
      'medias': mediaIds,
      'ubicacion_lat': lat,
      'ubicacion_lng': lng,
      'ubicacion_label': locationLabel,
    });

    debugPrint(response.body);

    if (response.statusCode == 201) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al crear post');
  }

  static Future<Post> updatePost(
    String postId, {
    String? description,
    String? telefono,
    String? postTypeId,
    List<String>? mediaIds,
  }) async {
    final token = await AuthService.getAccessToken();

    final body = <String, dynamic>{};
    if (description != null) body['descripcion'] = description;
    if (telefono != null) body['telefono'] = telefono;
    if (postTypeId != null) body['posteo_tipo'] = postTypeId;
    if (mediaIds != null) body['medias'] = mediaIds;

    final response = await http.put(
      Uri.parse('${Config.baseUrl}/api/posteos/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar post: ${response.body}');
  }

  static Future<bool> deletePost(String postId) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/posteos/$postId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // REACTIONS

  static Future<bool> addReaction(int postId, int typeId) async {
    final response = await AuthService.postWithToken('/api/reacciones/', {
      'posteo': postId,
      'tipo': typeId,
    });

    return response.statusCode == 201;
  }

  static Future<bool> removeReaction(String reactionId) async {
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/reacciones/$reactionId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // COMMENTS

  static Future<List<Comment>> getComments(String postId) async {
    final response = await AuthService.getWithToken(
      '/api/comentarios/?posteo=$postId',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((json) => Comment.fromJson(json)).toList();
    }

    throw Exception('Error al cargar comentarios');
  }

  static Future<bool> addComment(String postId, String text) async {
    final response = await AuthService.postWithToken('/api/comentarios/', {
      'posteo': postId,
      'body': text,
    });

    return response.statusCode == 201;
  }

  // FILTERS

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

  // utils

  static Post _parsePost(Map<String, dynamic> json) {
    final rawMedias = json['medias'];
    final List<PostMedia> medias = [];

    if (rawMedias != null && rawMedias is List) {
      for (final m in rawMedias) {
        if (m == null) continue;
        medias.add(PostMedia.fromJson(m));
      }
    }

    return Post(
      id: json['id'].toString(),
      user: UserProfile.fromJson(json['usuario'] ?? {}),
      postType: PostType(
        id: json['posteo_tipo']['id'].toString(),
        name: json['posteo_tipo']['nombre'] ?? '',
        color: json['posteo_tipo']['color'],
        icon: json['posteo_tipo']['icono'],
      ),
      petType: PetType(
        id: json['mascota_tipo']['id'].toString(),
        name: json['mascota_tipo']['nombre'] ?? '',
      ),
      medias: medias,
      description: json['descripcion'] ?? '',
      telefono: json['telefono'],
      location: PostLocation(
        id: json['id'].toString(),
        lat: (json['ubicacion_lat'] ?? 0).toDouble(),
        lng: (json['ubicacion_lng'] ?? 0).toDouble(),
        label: json['ubicacion_label'] ?? '',
      ),
      datetime:
          DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
      likes: json['total_reacciones'] ?? 0,
      comments: json['total_comentarios'] ?? 0,
      reacciones:
          (json['reacciones'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}
