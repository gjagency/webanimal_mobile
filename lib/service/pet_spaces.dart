import 'dart:convert';

import 'package:mobile_app/service/auth_service.dart';

class NegocioAnimal {
  final String userId;
  final String nombreComercio;
  final String? avatar;
  final String? categoria;
  final String? descripcion;
  final String? direccion;
  final double? lat;
  final double? lng;
  final double? distanciaKm;
  final List<ServicioItem> servicios;

  const NegocioAnimal({
    required this.userId,
    required this.nombreComercio,
    this.avatar,
    this.categoria,
    this.descripcion,
    this.direccion,
    this.lat,
    this.lng,
    this.distanciaKm,
    required this.servicios,
  });

  factory NegocioAnimal.fromJson(Map<String, dynamic> json) {
    return NegocioAnimal(
      userId: json['userId']?.toString() ?? '',
      nombreComercio: json['nombreComercio'] ?? '',
      avatar: json['avatar'],
      categoria: json['categoria'],
      descripcion: json['descripcion'],
      direccion: json['direccion'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble(),
      servicios: (json['servicios'] as List<dynamic>? ?? [])
          .map((s) => ServicioItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ServicioItem {
  final String titulo;
  final String descripcion;
  final String? imagen;
  final String? precio;

  const ServicioItem({
    required this.titulo,
    required this.descripcion,
    this.imagen,
    this.precio,
  });

  factory ServicioItem.fromJson(Map<String, dynamic> json) {
    return ServicioItem(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagen: json['imagen'],
      precio: json['precio']?.toString(),
    );
  }
}

class PetSpacesService {
  static Future<List<NegocioAnimal>> getPetSpaces({
    double? lat,
    double? lng,
  }) async {
    final params = <String, String>{};
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();

    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await AuthService.getWithToken('/api/pet_spaces/$query');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded is Map ? decoded['results'] ?? [] : decoded;
      return data
          .map<NegocioAnimal>(
            (json) => NegocioAnimal.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception('Error al cargar Espacio Animal');
  }
}
