import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config.dart';

class LocationResult {
  final String displayName;
  final String city;
  final String state;
  final String country;
  final double lat;
  final double lng;

  LocationResult({
    required this.displayName,
    required this.city,
    required this.state,
    required this.country,
    required this.lat,
    required this.lng,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};

    String city =
        address['city'] ?? address['town'] ?? address['village'] ?? '';

    final state = address['state'] ?? '';
    final country = address['country'] ?? '';

    city = city
        .replaceAll('Municipio de ', '')
        .replaceAll('Municipality of ', '')
        .trim();

    return LocationResult(
      displayName: '$city, $state, $country',
      city: city,
      state: state,
      country: country,
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lon'].toString()),
    );
  }
}

class LocationService {
  static Future<List<LocationResult>> searchLocation(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=jsonv2'
        '&addressdetails=1'
        '&limit=10',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'webanimal-app'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((item) => LocationResult.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat'
        '&lon=$lng'
        '&format=jsonv2'
        '&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'webanimal-app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        final city =
            (address['city'] ?? address['town'] ?? address['village'] ?? '')
                .toString()
                .replaceAll('Municipio de ', '')
                .replaceAll('Municipality of ', '')
                .trim();

        final state = address['state'] ?? '';
        final country = address['country'] ?? '';

        return '$city, $state, $country';
      }

      return 'Ubicación no disponible';
    } catch (e) {
      return 'Ubicación no disponible';
    }
  }

  static Future<LocationResult?> reverseGeocodeLocation(
    double lat,
    double lng,
  ) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat'
        '&lon=$lng'
        '&format=jsonv2'
        '&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'webanimal-app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        return LocationResult(
          displayName: '',
          city: (address['city'] ?? address['town'] ?? address['village'] ?? '')
              .toString()
              .replaceAll('Municipio de ', '')
              .replaceAll('Municipality of ', '')
              .trim(),
          state: address['state'] ?? '',
          country: address['country'] ?? "",
          lat: lat,
          lng: lng,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
