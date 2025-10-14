import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';
import 'api_service.dart';

class RestaurantService {
  static String get _baseUrl => '${ApiService.baseUrl}/restaurants';

  /// Récupère tous les restaurants
  static Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des restaurants: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère un restaurant par son ID
  static Future<Restaurant?> getRestaurantById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Restaurant.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors du chargement du restaurant: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Crée une map des restaurants par ID pour un accès rapide
  static Future<Map<int, Restaurant>> getRestaurantsMap() async {
    try {
      final restaurants = await getAllRestaurants();
      return {for (var restaurant in restaurants) restaurant.id: restaurant};
    } catch (e) {
      // print('❌ [RestaurantService] Erreur lors de la récupération des restaurants: $e');
      return {};
    }
  }
}
