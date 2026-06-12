import 'dart:convert';

import 'package:mobile_app/service/auth_service.dart';

enum UserReportType {
  BLOQUEO_USUARIO,
  BLOQUEO_VETERINARIA,

  REPORTE_USUARIO,
  REPORTE_POSTEO,
  REPORTE_COMENTARIO,
  REPORTE_VETERINARIA,
  REPORTE_PROMOCION,
}

enum UserReportState { PENDIENTE, ACEPTADO, RECHAZADO, CANCELADO }

class UserReport {
  final int id;
  final UserReportType type;
  final String target;
  final String value;
  final UserReportState state;
  final Map<String, dynamic> targetDetail;
  final DateTime createdAt;

  UserReport({
    required this.id,
    required this.type,
    required this.target,
    required this.value,
    required this.state,
    required this.targetDetail,
    required this.createdAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'],
      type: UserReportType.values.firstWhere((e) => e.name == json['tipo']),
      target: json['target'],
      value: json['value'],
      state: UserReportState.values.firstWhere((e) => e.name == json['estado']),
      targetDetail: json['target_detail'],
      createdAt: DateTime.parse(json['fecha_creacion']),
    );
  }
}

class ReportService {
  static Future<UserReport> set({
    required UserReportType type,
    required String value,
    required UserReportState state,
    String reason = '',
  }) async {
    final response = await AuthService.postWithToken('/api/reports/', {
      'tipo': type.name,
      'value': value,
      'estado': state.name,
      'razon': reason,
    });

    if (response.statusCode >= 200 || response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UserReport.fromJson(decoded);
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al crear report');
    } catch (_) {
      throw Exception('Error al crear report (${response.statusCode})');
    }
  }

  static Future<List<UserReport>> get({
    UserReportType? tipo,
    String? value,
    UserReportState? estado,
    int take = 20,
    int skip = 0,
  }) async {
    final params = <String, String>{
      'take': take.toString(),
      'skip': skip.toString(),
      if (tipo != null) 'tipo': tipo.name,
      if (value != null) 'value': value,
      if (estado != null) 'estado': estado.name,
    };

    final query = Uri(queryParameters: params).query;

    final response = await AuthService.getWithToken('/api/reports/?$query');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      final results = (decoded['results'] as List)
          .map((json) => UserReport.fromJson(json as Map<String, dynamic>))
          .toList();

      return results;
    }

    throw Exception('Error al obtener reportes (${response.statusCode})');
  }
}
