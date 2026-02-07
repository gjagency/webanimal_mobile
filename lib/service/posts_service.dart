import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';

class PetType {
  final String id;
  final String name;

  PetType({
    required this.id,
    required this.name,
  });

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

  PostType({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

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


class PromocionesPorVeterinaria {
  final int veterinariaId;
  final String nombreComercio;
  final String? precio;
  final List<Promocion> promociones;

  PromocionesPorVeterinaria({
    required this.veterinariaId,
    required this.nombreComercio,
    required this.promociones,
    required this.precio,
  });

  factory PromocionesPorVeterinaria.fromJson(Map<String, dynamic> json) {
    return PromocionesPorVeterinaria(
      veterinariaId: json['veterinaria_id'],
      nombreComercio: json['nombreComercio'],
      precio: json['precio']?.toString(),
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
class Post {
  final String id;
  final PostUser user;
  final PostType postType;
  final PetType petType;
  final List<String> imageUrls;
  final String description;
  final String? telefono;
  final PostLocation location;
  final DateTime datetime;
  final int likes;
  final int comments;
  final List<String> reacciones;
  final Map<String, int> imageIdByUrl;


  Post({
    required this.id,
    required this.user,
    required this.postType,
    required this.petType,
    this.imageUrls = const [],
    required this.description,
    this.telefono,
    required this.location,
    required this.datetime,
    this.likes = 0,
    this.comments = 0,
    this.reacciones = const [],
    this.imageIdByUrl = const {},

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

class PostImage {
  final int? id;   // ← ahora permite null
  final String url;
  bool markedForDelete; // flag para marcar borrado
  PostImage({
    this.id,
    required this.url,
    this.markedForDelete = false,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'],
      url: json['imagen'],
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
    required List<String> imagesBase64,
    required double lat,
    required double lng,
    required String locationLabel,
  }) async {
    final response = await AuthService.postWithToken('/api/posteos/', {
      'posteo_tipo': postTypeId,
      'mascota_tipo': petTypeId,
      'descripcion': description,
      'telefono': telefono,
      'imagenes': imagesBase64,
      'ubicacion_lat': lat,
      'ubicacion_lng': lng,
      'ubicacion_label': locationLabel,
    });

    if (response.statusCode == 201) {
      return _parsePost(jsonDecode(response.body));
    }
    throw Exception('Error al crear post');
  }

static Future<void> updatePostWithImages({
  
  required String postId,
  Map<String, String>? fields,
  List<File>? newImages,
  List<int>? deleteImageIds,
}) async {
  final token = await AuthService.getAccessToken();
print("IMAGES TO DELETE: $deleteImageIds");
  final uri = Uri.parse('${Config.baseUrl}/api/posteos/$postId/');
  final request = http.MultipartRequest('PUT', uri);

  request.headers['Authorization'] = 'Bearer $token';

  // =========================
  // 🔹 CAMPOS NORMALES
  // =========================
  if (fields != null) {
    fields.removeWhere((k, v) => v.isEmpty); // evita mandar ""
    request.fields.addAll(fields);
  }

  // =========================
  // 🗑️ IDS A BORRAR
  // =========================
if (deleteImageIds != null && deleteImageIds.isNotEmpty) {
  request.fields['delete_images'] = jsonEncode(deleteImageIds);
  print("🗑️ DELETE IDS SENT: ${jsonEncode(deleteImageIds)}");
} else {
  // NO se manda el campo si está vacío
  print("🗑️ DELETE IDS SENT: NONE");
}


  // =========================
  // 📸 NUEVAS IMÁGENES
  // =========================
  if (newImages != null && newImages.isNotEmpty) {
    for (var img in newImages) {
      request.files.add(await http.MultipartFile.fromPath('imagenes', img.path));
    }
    print("📸 NEW IMAGES: ${newImages.length}");
  } else {
    print("📸 NEW IMAGES: 0");
  }

  // =========================
  // 🚀 ENVIAR
  // =========================
  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  print("UPDATE STATUS: ${response.statusCode}");
  print("UPDATE BODY: ${response.body}");

  if (response.statusCode != 200) {
    throw Exception("Error update post: ${response.body}");
  }
}


  // PUT: Actualizar post
  static Future<Post> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    final token = await AuthService.getAccessToken();

    // 🔹 Limpiar nulls para evitar 400 del backend
    updates.removeWhere((key, value) => value == null);

    final response = await http.put(
      Uri.parse('${Config.baseUrl}/api/posteos/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    // 👇 DEBUG REAL — MOSTRAR ERROR DEL BACKEND
    print("UPDATE STATUS: ${response.statusCode}");
    print("UPDATE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return _parsePost(jsonDecode(response.body));
    }

    throw Exception('Error al actualizar post: ${response.body}');
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
static Post _parsePost(Map<String, dynamic> json) {
  // ================= IMÁGENES =================
  final rawImages = json['imagenes'];
  final List<String> imageUrls = [];
  final Map<String, int> imageIdByUrl = {};

  if (rawImages != null && rawImages is List) {
    for (final img in rawImages) {
      if (img == null) continue;

      String url;
      int? id;

      if (img is String) {
        // Si la imagen viene como string
        url = img.startsWith('http') ? img : '${Config.baseUrl}$img';
      } else if (img is Map<String, dynamic>) {
        // Si la imagen viene como map
        final rawUrl = img['imagen'] ?? img['url'];
        if (rawUrl == null || rawUrl.toString().isEmpty) continue;

        url = rawUrl.toString();
        url = url.startsWith('http') ? url : '${Config.baseUrl}$url';

        // ID opcional
        if (img.containsKey('id')) {
          final parsedId = img['id'];
          if (parsedId != null) {
            id = parsedId is int ? parsedId : int.tryParse(parsedId.toString());
          }
        }
      } else {
        continue;
      }

      imageUrls.add(url);
      if (id != null) {
        imageIdByUrl[url] = id;
      }
    }
  }

  // ================= POST =================
  return Post(
    id: json['id'].toString(),
    user: PostUser.fromJson(json['usuario'] ?? {}),
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
    imageUrls: imageUrls,
    description: json['descripcion'] ?? '',
    telefono: json['telefono'],
    location: PostLocation(
      id: json['id'].toString(),
      lat: (json['ubicacion_lat'] ?? 0).toDouble(),
      lng: (json['ubicacion_lng'] ?? 0).toDouble(),
      label: json['ubicacion_label'] ?? '',
    ),
    datetime: DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
    likes: json['total_reacciones'] ?? 0,
    comments: json['total_comentarios'] ?? 0,
    reacciones: (json['reacciones'] as List?)?.map((e) => e.toString()).toList() ?? [],
    imageIdByUrl: imageIdByUrl,
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
