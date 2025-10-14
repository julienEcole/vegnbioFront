// lib/services/reports_admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vegnbio_front/config/app_config.dart';
import 'package:vegnbio_front/models/report.dart';

/// Service dédié à l'administration de la modération des signalements
class ReportsAdminService {
  final String _baseUrl = '${AppConfig.apiBaseUrl}/reports';

  /// GET /reports
  Future<ReportListResponse> listReports({
    required String token,
    String? status,
    String? category,
    String? targetType,
    int? restaurantId,
    String? q,
    int page = 1,
    int pageSize = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (status != null && status.isNotEmpty) 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
      if (targetType != null && targetType.isNotEmpty) 'targetType': targetType,
      if (restaurantId != null) 'restaurantId': '$restaurantId',
      if (q != null && q.isNotEmpty) 'q': q,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };
    final url = Uri.parse(_buildPath(_baseUrl, qp));
    // print('🌐 [ReportsAdminService] GET $url');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    // print('📥 [ReportsAdminService] GET status=${res.statusCode} body=${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');
    if (res.statusCode == 200) {
      return ReportListResponse.fromJson(json.decode(res.body));
    } else {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  /// PATCH /reports/:id
  Future<Report> updateStatus({
    required int id,
    required String status,
    String? resolutionNote,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/$id');
    // print('🌐 [ReportsAdminService] PATCH $url status=$status note=$resolutionNote');

    final res = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'status': status,
        if (resolutionNote != null && resolutionNote.isNotEmpty) 'resolutionNote': resolutionNote,
      }),
    );
    // print('📥 [ReportsAdminService] PATCH status=${res.statusCode} body=${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');
    if (res.statusCode == 200) {
      return Report.fromJson(json.decode(res.body));
    } else {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  String _buildPath(String base, Map<String, String> qp) {
    if (qp.isEmpty) return base;
    final qs = qp.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$base?$qs';
  }
}
