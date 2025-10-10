import 'dart:convert';
import 'package:http/http.dart' as http;

class OffresService {
  final String baseUrl;
  final Future<String?> Function() getToken;
  OffresService(this.baseUrl, {required this.getToken});

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<Map<String, dynamic>>> listOffres() async {
    final uri = Uri.parse('$baseUrl/offreRouter/offres');
    print('[OffresService] GET $uri'); // debug
    final res = await http.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Erreur listOffres: ${res.body}');
    }
    final parsed = jsonDecode(res.body);
    if (parsed is List) return parsed.cast<Map<String, dynamic>>();
    if (parsed is Map && parsed['data'] is List) {
      return (parsed['data'] as List).cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> createOffre(Map<String, dynamic> body) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/offreRouter/offres');
    final res = await http.post(uri, headers: _headers(token), body: jsonEncode(body));
    if (res.statusCode >= 400) {
      throw Exception('Erreur createOffre: ${res.body}');
    }
  }

  Future<void> updateOffre(int id, Map<String, dynamic> patch) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/offreRouter/offres/$id');
    final res = await http.patch(uri, headers: _headers(token), body: jsonEncode(patch));
    if (res.statusCode >= 400) {
      throw Exception('Erreur updateOffre: ${res.body}');
    }
  }

  Future<void> toggleDisponibilite(int id) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/offreRouter/offres/$id/toggle');
    final res = await http.patch(uri, headers: _headers(token));
    if (res.statusCode >= 400) {
      throw Exception('Erreur toggle: ${res.body}');
    }
  }

  Future<void> deleteOffre(int id) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/offreRouter/offres/$id');
    final res = await http.delete(uri, headers: _headers(token));
    if (res.statusCode >= 400) {
      throw Exception('Erreur deleteOffre: ${res.body}');
    }
  }
}
