import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

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
      id: json["id"] as String?,
      url: json["url"] as String?,
      filename: json["filename"] as String?,
      mimeType: json["mime_type"] as String?,
      size: json["size"] as int?,
    );
  }

  String getUrl() => url ?? "";
}

class MediaService {

  static final Dio _dio = Dio();

  static Future<Media> upload(
    File file, {
    Function(double progress)? onProgress,
  }) async {

    final token = await AuthService.getAccessToken();

    final mimeType =
        lookupMimeType(file.path) ??
        'application/octet-stream';

    final mimeParts = mimeType.split('/');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,

        contentType: MediaType(
          mimeParts[0],
          mimeParts[1],
        ),
      ),
    });

    final response = await _dio.post(
      '${Config.baseUrl}/api/media/upload/',

      data: formData,

      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },

        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),

      onSendProgress: (sent, total) {

        if (total <= 0) return;

        final progress = sent / total;

        print(
          'UPLOAD ${(progress * 100).toStringAsFixed(0)}%',
        );

        onProgress?.call(progress);
      },
    );

    debugPrint(jsonEncode(response.data));

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      return Media.fromJson(response.data);
    }

    throw Exception(
      'Error al subir media: ${response.data}',
    );
  }
}