import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mobile_app/config.dart';
import 'package:mobile_app/service/auth_service.dart';

class Media {
  final String? id;
  final String? url;
  final String? filename;
  final String? mimeType;
  final int? size;

  Media({
    required this.id,
    required this.url,
    required this.filename,
    required this.mimeType,
    required this.size,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json.containsKey("id") && json["id"] != null
          ? json['id'] as String
          : null,
      url: json.containsKey("url") && json["url"] != null
          ? json['url'] as String
          : null,
      filename: json.containsKey("filename") && json["filename"] != null
          ? json['filename'] as String
          : null,
      mimeType: json.containsKey("mime_type") && json["mime_type"] != null
          ? json['mime_type'] as String
          : null,
      size: json.containsKey("size") && json["size"] != null
          ? json['size'] as int
          : null,
    );
  }

  String getUrl() => url ?? "";
}

class MediaService {
  static Future<Media> upload(File file) async {
    final token = await AuthService.getAccessToken();
    final uri = Uri.parse('${Config.baseUrl}/api/media/upload/');

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeParts = mimeType.split('/');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint(response.body);

    if (response.statusCode == 201) {
      return Media.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error al subir media: ${response.body}');
  }
}
