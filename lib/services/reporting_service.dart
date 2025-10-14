// lib/services/reporting_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vegnbio_front/config/app_config.dart';
import 'package:vegnbio_front/models/report.dart';
import 'package:vegnbio_front/models/report_request.dart';

class ReportingService {
  final String _baseUrl = '${AppConfig.apiBaseUrl}/reports';

  /// POST /reports/createReport
  Future<void> createReport(ReportRequest req, {required String token}) async {
    final url = Uri.parse('$_baseUrl/createReport');
    // print('🌐 [ReportingService] POST $url');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(req.toJson()),
    );
    // print('📥 [ReportingService] POST status=${res.statusCode} body=${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  /// GET /reports
  Future<ReportListResponse> fetchReports({
    required String token,
    String? status,
    String? category,
    String? targetType,
    int page = 1,
    int pageSize = 20,
    String? q,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (status != null && status.isNotEmpty) 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
      if (targetType != null && targetType.isNotEmpty) 'targetType': targetType,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final url = Uri.parse(_withQuery('$_baseUrl', qp));
    // print('🌐 [ReportingService] GET $url');

    final res = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    // print('📥 [ReportingService] GET status=${res.statusCode} body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return ReportListResponse.fromJson(json.decode(res.body));
  }

  /// GET /reports/:id
  Future<Report> getReportById(int id, {required String token}) async {
    final url = Uri.parse('$_baseUrl/$id');
    // print('🌐 [ReportingService] GET $url');
    final res = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    // print('📥 [ReportingService] GET by id status=${res.statusCode} body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final payload = json.decode(res.body);
    return Report.fromJson(payload);
  }

  String _withQuery(String base, Map<String, String> qp) {
    if (qp.isEmpty) return base;
    final qs = qp.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$base?$qs';
  }
}
