import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu.dart';
import 'api_service.dart';

class MenuService {
  static String get _baseUrl => '${ApiService.baseUrl}/menus';

  /// Récupère tous les menus
  static Future<List<Menu>> getAllMenus() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Menu.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des menus: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère un menu par son ID
  static Future<Menu?> getMenuById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Menu.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors du chargement du menu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Crée une map des menus par ID pour un accès rapide
  static Future<Map<int, Menu>> getMenusMap() async {
    try {
      final menus = await getAllMenus();
      return {for (var menu in menus) menu.id: menu};
    } catch (e) {
      // print('❌ [MenuService] Erreur lors de la récupération des menus: $e');
      return {};
    }
  }
}
