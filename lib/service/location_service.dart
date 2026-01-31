import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';

class LocationResult {
  final String displayName;
  final double lat;
  final double lng;

  LocationResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'] ?? '0'),
      lng: double.parse(json['lon'] ?? '0'),
    );
  }
}

class LocationService {
  static Future<List<LocationResult>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        '${Config.baseUrl}/api/locations/search/',
      ).replace(queryParameters: {'q': query});

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationResult.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching location: $e');
      return [];
    }
  }

  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse('${Config.baseUrl}/api/locations/reverse/').replace(
        queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Ubicación desconocida';
      }
      return 'Ubicación desconocida';
    } catch (e) {
      print('Error reverse geocoding: $e');
      return 'Error obteniendo ubicación';
    }
  }
}
