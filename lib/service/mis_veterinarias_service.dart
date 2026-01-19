import 'dart:convert';
import 'package:mobile_app/service/auth_service.dart';

class MiVeterinariaLocation {
  final String country;
  final String state;
  final String city;
  final String address;
  final double lat;
  final double lng;

  MiVeterinariaLocation({
    required this.country,
    required this.state,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class MiVeterinaria {
  final String id;
  final String name;
  final String phone;
  final String? imageUrl;
  final bool verified;
  final MiVeterinariaLocation location;

  MiVeterinaria({
    required this.id,
    required this.name,
    required this.phone,
    this.imageUrl,
    required this.verified,
    required this.location,
  });
}

class MisVeterinariasService {
  // GET: Lista de veterinarias
  static Future<List<MiVeterinaria>> getAll() async {
    final response = await AuthService.getWithToken('/api/mis_veterinarias/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((json) => _parseVet(json)).toList();
    }

    throw Exception('Error al cargar veterinarias: ${response.statusCode}');
  }

  // GET: Veterinaria individual
  static Future<MiVeterinaria> getOne(String id) async {
    final response = await AuthService.getWithToken(
      '/api/mis_veterinarias/$id/',
    );

    if (response.statusCode == 200) {
      return _parseVet(jsonDecode(response.body));
    }

    throw Exception('Error al cargar veterinaria: ${response.statusCode}');
  }

  // POST: Crear veterinaria
  static Future<MiVeterinaria> register({
    required String name,
    required String phone,
    String? imageBase64,
    required MiVeterinariaLocation location,
  }) async {
    final body = {
      'nombre_comercial': name,
      'telefono': phone,
      'pais': location.country,
      'estado': location.state,
      'ciudad': location.city,
      'direccion': location.address,
      'lat': location.lat,
      'lng': location.lng,
    };

    if (imageBase64 != null) {
      body['imagen'] = imageBase64;
    }

    final response = await AuthService.postWithToken(
      '/api/mis_veterinarias/',
      body,
    );

    if (response.statusCode == 201) {
      return _parseVet(jsonDecode(response.body));
    }

    throw Exception('Error al crear veterinaria: ${response.statusCode}');
  }

  // PUT: Modificar veterinaria
  static Future<MiVeterinaria> modify({
    required String id,
    required String name,
    required String phone,
    String? imageBase64,
    required MiVeterinariaLocation location,
  }) async {
    final body = {
      'nombre_comercial': name,
      'telefono': phone,
      'pais': location.country,
      'estado': location.state,
      'ciudad': location.city,
      'direccion': location.address,
      'lat': location.lat,
      'lng': location.lng,
    };

    if (imageBase64 != null) {
      body['imagen'] = imageBase64;
    }

    final response = await AuthService.putWithToken(
      '/api/mis_veterinarias/$id/',
      body,
    );

    if (response.statusCode == 200) {
      return _parseVet(jsonDecode(response.body));
    }

    throw Exception('Error al modificar veterinaria: ${response.statusCode}');
  }

  // DELETE: Eliminar veterinaria
  static Future<bool> remove({required String id}) async {
    final response = await AuthService.deleteWithToken(
      '/api/mis_veterinarias/$id/',
      {},
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception('Error al eliminar veterinaria: ${response.statusCode}');
  }

  // Parser privado
  static MiVeterinaria _parseVet(Map<String, dynamic> json) {
    return MiVeterinaria(
      id: json['id'].toString(),
      name: json['nombre_comercial'],
      phone: json['telefono'] ?? '',
      imageUrl: json['imagen'],
      verified: json['verificada'] ?? false,
      location: MiVeterinariaLocation(
        country: json['pais'] ?? '',
        state: json['estado'] ?? '',
        city: json['ciudad'] ?? '',
        address: json['direccion'] ?? '',
        lat: json['lat'] ?? 0.0,
        lng: json['lng'] ?? 0.0,
      ),
    );
  }
}
