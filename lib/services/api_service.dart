import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/menu.dart';

class ApiService {
  // Configuration dynamique de l'URL selon l'environnement
  static String get baseUrl {
    // En développement local ou si l'API est accessible directement
    return 'http://localhost:3000/api';
  }
  
  // Configuration pour les requêtes HTTP
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Récupérer tous les restaurants
  Future<List<Restaurant>> getRestaurants() async {
    try {
      print('🔗 Tentative de connexion à: $baseUrl/restaurants');
      
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('📡 Statut de réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('📄 Corps de réponse reçu: ${response.body.substring(0, 200)}...');
        try {
          final List<dynamic> jsonData = json.decode(response.body);
          print('🔢 Nombre de restaurants trouvés: ${jsonData.length}');
          
          final List<Restaurant> restaurants = [];
          for (int i = 0; i < jsonData.length; i++) {
            try {
              final restaurant = Restaurant.fromJson(jsonData[i] as Map<String, dynamic>);
              restaurants.add(restaurant);
              print('✅ Restaurant ${i + 1} parsé: ${restaurant.nom}');
            } catch (e) {
              print('❌ Erreur parsing restaurant ${i + 1}: $e');
              print('📄 Données du restaurant ${i + 1}: ${jsonData[i]}');
              rethrow;
            }
          }
          return restaurants;
        } catch (e) {
          print('❌ Erreur de parsing JSON: $e');
          print('📄 Réponse complète: ${response.body}');
          rethrow;
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur de connexion détaillée: $e');
      
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('ERR_CONNECTION_REFUSED')) {
        throw Exception('❌ Impossible de se connecter à l\'API sur $baseUrl.\n'
                       '🔧 Vérifiez que le backend est en cours d\'exécution:\n'
                       '   cd vegnbio-api && docker-compose up');
      }
      
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer un restaurant par ID
  Future<Restaurant> getRestaurant(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Restaurant.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de la récupération du restaurant: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer tous les menus
  Future<List<Menu>> getMenus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menus'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Menu.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des menus: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer un menu par ID
  Future<Menu> getMenu(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menus/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Menu.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors de la récupération du menu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les menus d'un restaurant
  Future<List<Menu>> getMenusByRestaurant(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menus/restaurant/$restaurantId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Menu.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des menus du restaurant: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Rechercher des menus avec critères avancés
  Future<List<Menu>> searchMenus({
    String? titre,
    String? allergene,
    List<String>? allergenesExclus,
    List<String>? allergenesInclus,
    int? restaurantId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      
      if (titre != null && titre.isNotEmpty) {
        queryParams['titre'] = titre;
      }
      
      if (allergene != null && allergene.isNotEmpty) {
        queryParams['allergene'] = allergene;
      }
      
      if (allergenesExclus != null && allergenesExclus.isNotEmpty) {
        queryParams['allergenes_exclus'] = allergenesExclus.join(',');
      }
      
      if (allergenesInclus != null && allergenesInclus.isNotEmpty) {
        queryParams['allergenes_inclus'] = allergenesInclus.join(',');
      }
      
      if (restaurantId != null) {
        queryParams['restaurant_id'] = restaurantId.toString();
      }
      
      if (dateDebut != null) {
        queryParams['date_debut'] = dateDebut.toIso8601String().split('T')[0];
      }
      
      if (dateFin != null) {
        queryParams['date_fin'] = dateFin.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$baseUrl/menus/search').replace(queryParameters: queryParams);
      print('🔍 Recherche menus avec URL: $uri');
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('🔢 Nombre de menus trouvés: ${jsonData.length}');
        return jsonData.map((json) => Menu.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la recherche de menus: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur recherche menus: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Recherche de menus simplifiée (pour compatibilité)
  Future<List<Menu>> searchMenusSimple({String? titre, String? allergene}) async {
    return searchMenus(titre: titre, allergene: allergene);
  }

  // Récupérer tous les allergènes disponibles dans les menus
  Future<List<String>> getAvailableAllergenes() async {
    print('🔍 Récupération des allergènes disponibles...');
    
    // Directement utiliser l'extraction depuis les menus
    // car l'endpoint /menus/allergenes n'existe pas encore côté backend
    return _extractAllergenesFromMenus();
  }

  // Méthode fallback pour extraire les allergènes depuis tous les menus
  Future<List<String>> _extractAllergenesFromMenus() async {
    try {
      print('📋 Récupération de tous les menus pour extraire les allergènes...');
      final menus = await getMenus();
      print('📊 Nombre de menus récupérés: ${menus.length}');
      
      final Set<String> allAllergenes = {};
      
      for (int i = 0; i < menus.length; i++) {
        final menu = menus[i];
        print('🍽️  Menu ${i + 1}: "${menu.titre}" - Allergènes: ${menu.allergenes}');
        if (menu.allergenes.isNotEmpty) {
          allAllergenes.addAll(menu.allergenes);
        }
      }
      
      final allergenes = allAllergenes.toList()..sort();
      print('🏷️  ALLERGÈNES FINAUX EXTRAITS: $allergenes');
      print('🔢 Nombre total d\'allergènes uniques: ${allergenes.length}');
      
      return allergenes;
    } catch (e) {
      print('❌ Erreur extraction allergènes: $e');
      return [];
    }
  }

  // Vérifier la santé de l'API
  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
