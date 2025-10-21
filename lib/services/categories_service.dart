// lib/services/categories_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vegnbio_front/config/app_config.dart';
import 'package:vegnbio_front/models/categorie.dart';

class CategoriesService {
  // Si AppConfig.apiBaseUrl = 'http://localhost:3001/api',
  String get _base => AppConfig.apiBaseUrl;
  Uri _u(String path) => Uri.parse('$_base$path');

  /// Récupérer toutes les catégories (public)
  Future<List<Categorie>> listCategories() async {
    final res = await http.get(_u('/categorieRouter/categories'));

    if (res.statusCode != 200) {
      throw Exception('Erreur ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    // Accepte { data: [...] } ou bien un tableau direct
    final List data = (body is Map && body['data'] is List) ? body['data'] : (body as List);
    return data.map((e) => Categorie.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Créer une catégorie (admin)
  Future<Categorie> createCategorie({
    required String nom,
    required String token,
  }) async {
    final res = await http.post(
      _u('/categorieRouter/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ⬅️ rôle admin requis côté back
      },
      body: jsonEncode(CategorieCreateRequest(nom).toJson()),
    );

    if (res.statusCode != 201) {
      throw Exception('Erreur création catégorie (${res.statusCode}) : ${res.body}');
    }

    final body = jsonDecode(res.body);
    return Categorie.fromJson(body as Map<String, dynamic>);
  }
}
