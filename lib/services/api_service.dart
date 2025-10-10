import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/restaurant.dart';
import '../models/menu.dart';
import '../models/commande.model.dart';
import '../models/cart_item.dart';
import '../config/app_config.dart';


class ApiService {
  // Configuration unifiée de l'URL pour tous les environnements
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Configuration pour les requêtes HTTP
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

// 🔧 Construit des headers JSON + Authorization (optionnelle)
  Map<String, String> _jsonHeaders({String? token, Map<String, String>? extra}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (extra != null) h.addAll(extra);
    return h;
  }

  /// 🔁 Requête générique JSON (GET/POST/PUT/DELETE)
  Future<http.Response> request(
      String path, {
        String method = 'GET',
        Map<String, dynamic>? body,
        String? token, // JWT optionnel
        Duration timeout = const Duration(seconds: 20),
      }) async {
    final uri = Uri.parse('$baseUrl$path');
    final hdrs = _jsonHeaders(token: token);

    http.Response res;
    switch (method.toUpperCase()) {
      case 'POST':
        res = await http
            .post(uri, headers: hdrs, body: body != null ? json.encode(body) : null)
            .timeout(timeout);
        break;
      case 'PUT':
        res = await http
            .put(uri, headers: hdrs, body: body != null ? json.encode(body) : null)
            .timeout(timeout);
        break;
      case 'DELETE':
        res = await http
            .delete(uri, headers: hdrs, body: body != null ? json.encode(body) : null)
            .timeout(timeout);
        break;
      default: // GET
        res = await http.get(uri, headers: hdrs).timeout(timeout);
    }

    return res;
  }

  /// ✉️ POST JSON + parse auto en Map/List
  Future<dynamic> postJson(
      String path, {
        Map<String, dynamic>? body,
        String? token, // JWT optionnel
        int ok = 201,  // 201 pour création
      }) async {
    final res = await request(
      path,
      method: 'POST',
      body: body,
      token: token,
    );

    if (res.statusCode == ok || res.statusCode == 200) {
      if (res.body.isEmpty) return null;
      try {
        return json.decode(res.body);
      } catch (_) {
        return res.body;
      }
    } else {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

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
    
    try {
      final result = await _extractAllergenesFromMenus();
      print('✅ getAvailableAllergenes retourne: $result');
      return result;
    } catch (e) {
      print('❌ Erreur dans getAvailableAllergenes: $e');
      return [];
    }
  }

  // Récupérer tous les produits disponibles dans les menus
  Future<List<String>> getAvailableProduits() async {
    print('🔍 Récupération des produits disponibles...');
    
    try {
      final result = await _extractProduitsFromMenus();
      print('✅ getAvailableProduits retourne: $result');
      return result;
    } catch (e) {
      print('❌ Erreur dans getAvailableProduits: $e');
      return [];
    }
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

  // Méthode fallback pour extraire les produits depuis tous les menus
  Future<List<String>> _extractProduitsFromMenus() async {
    try {
      print('📋 Récupération de tous les menus pour extraire les produits...');
      final menus = await getMenus();
      print('📊 Nombre de menus récupérés: ${menus.length}');
      
      final Set<String> allProduits = {};
      
      for (int i = 0; i < menus.length; i++) {
        final menu = menus[i];
        print('🍽️  Menu ${i + 1}: "${menu.titre}" - Produits: ${menu.produits}');
        if (menu.produits.isNotEmpty) {
          allProduits.addAll(menu.produits);
        }
      }
      
      final produits = allProduits.toList()..sort();
      print('🏷️  PRODUITS FINAUX EXTRAITS: $produits');
      print('🔢 Nombre total de produits uniques: ${produits.length}');
      
      return produits;
    } catch (e) {
      print('❌ Erreur extraction produits: $e');
      return [];
    }
  }

  // Vérifier la santé de l'API
  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Récupérer l'image principale d'un restaurant
  Future<String?> getRestaurantPrimaryImage(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images/restaurant/$restaurantId/primary'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['imageUrl'] != null) {
          return data['imageUrl'] as String;
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération image principale: $e');
      return null;
    }
  }

  // Récupérer toutes les images d'un restaurant
  Future<List<Map<String, dynamic>>> getRestaurantImages(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images/restaurant/$restaurantId/all'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['images'] != null) {
          return (data['images'] as List).map((img) => img as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur récupération images restaurant: $e');
      return [];
    }
  }

  // Récupérer l'image d'un menu
  Future<String?> getMenuImage(int menuId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images/menu/$menuId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['imageUrl'] != null) {
          return data['imageUrl'] as String;
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération image menu: $e');
      return null;
    }
  }

  // Upload d'image pour un restaurant
  Future<Map<String, dynamic>> uploadRestaurantImage(int restaurantId, File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/restaurants/$restaurantId/image');
      final request = http.MultipartRequest('POST', uri);
      
      // Déterminer le type MIME du fichier
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      
      // Ajouter le fichier à la requête
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);
      
      print('📤 Upload image restaurant - URI: $uri');
      print('📎 Fichier: ${imageFile.path}');
      print('🎯 Type MIME: $mimeType');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('📡 Statut upload: ${response.statusCode}');
      print('📄 Réponse: $responseBody');
      
      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Erreur upload image restaurant: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('❌ Erreur upload image restaurant: $e');
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  // Upload d'image pour un menu
  Future<Map<String, dynamic>> uploadMenuImage(int menuId, File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/menus/$menuId/image');
      final request = http.MultipartRequest('POST', uri);
      
      // Déterminer le type MIME du fichier
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      
      // Ajouter le fichier à la requête
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);
      
      print('📤 Upload image menu - URI: $uri');
      print('📎 Fichier: ${imageFile.path}');
      print('🎯 Type MIME: $mimeType');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('📡 Statut upload: ${response.statusCode}');
      print('📄 Réponse: $responseBody');
      
      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Erreur upload image menu: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('❌ Erreur upload image menu: $e');
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  // ===== CRUD RESTAURANTS =====
  
  /// Créer un nouveau restaurant
  Future<Restaurant> createRestaurant({
    required String nom,
    required String quartier,
    String? adresse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants'),
        headers: headers,
        body: json.encode({
          'nom': nom,
          'quartier': quartier,
          'adresse': adresse,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Restaurant.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création du restaurant');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour un restaurant
  Future<Restaurant> updateRestaurant({
    required int id,
    String? nom,
    String? quartier,
    String? adresse,
  }) async {
    try {
      print('🔄 API: Début updateRestaurant pour ID $id');
      final Map<String, dynamic> updateData = {};
      
      if (nom != null) updateData['nom'] = nom;
      if (quartier != null) updateData['quartier'] = quartier;
      if (adresse != null) updateData['adresse'] = adresse;

      print('📤 API: Données à envoyer: $updateData');

      final response = await http.put(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: headers,
        body: json.encode(updateData),
      );

      print('📥 API: Réponse status: ${response.statusCode}');
      print('📥 API: Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final restaurant = Restaurant.fromJson(jsonData);
        print('✅ API: Restaurant mis à jour: ${restaurant.nom}');
        return restaurant;
      } else {
        final errorData = json.decode(response.body);
        print('❌ API: Erreur mise à jour restaurant: ${errorData['message']}');
        throw Exception(errorData['message'] ?? 'Erreur lors de la mise à jour du restaurant');
      }
    } catch (e) {
      print('❌ API: Exception updateRestaurant: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprimer un restaurant
  Future<bool> deleteRestaurant(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('❌ Erreur suppression restaurant: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception suppression restaurant: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ===== CRUD MENUS =====
  
  /// Créer un nouveau menu
  Future<Menu> createMenu({
    required String titre,
    String? description,
    required DateTime date,
    required List<String> allergenes,
    required List<String> produits,
    required int restaurantId,
    required double prix,
    required bool disponible,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/menus'),
        headers: headers,
        body: json.encode({
          'titre': titre,
          'description': description,
          'date': date.toIso8601String().split('T')[0],
          'allergenes': allergenes,
          'produits': produits,
          'restaurant_id': restaurantId,
          'prix': prix,
          'disponible': disponible,
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Menu.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création du menu');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour un menu
  Future<Menu> updateMenu({
    required int id,
    String? titre,
    String? description,
    DateTime? date,
    List<String>? allergenes,
    List<String>? produits,
    int? restaurantId,
    double? prix,
    bool? disponible,
    String? imageUrl,
  }) async {
    try {
      print('🔄 API: Début updateMenu pour ID $id');
      final Map<String, dynamic> updateData = {};
      
      if (titre != null) updateData['titre'] = titre;
      if (description != null) updateData['description'] = description;
      if (date != null) updateData['date'] = date.toIso8601String().split('T')[0];
      if (allergenes != null) updateData['allergenes'] = allergenes;
      if (produits != null) updateData['produits'] = produits;
      if (restaurantId != null) updateData['restaurant_id'] = restaurantId;
      if (prix != null) updateData['prix'] = prix;
      if (disponible != null) updateData['disponible'] = disponible;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      print('📤 API: Données à envoyer: $updateData');

      final response = await http.put(
        Uri.parse('$baseUrl/menus/$id'),
        headers: headers,
        body: json.encode(updateData),
      );

      print('📥 API: Réponse status: ${response.statusCode}');
      print('📥 API: Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final menu = Menu.fromJson(jsonData);
        print('✅ API: Menu mis à jour: ${menu.titre}');
        return menu;
      } else {
        final errorData = json.decode(response.body);
        print('❌ API: Erreur mise à jour menu: ${errorData['message']}');
        throw Exception(errorData['message'] ?? 'Erreur lors de la mise à jour du menu');
      }
    } catch (e) {
      print('❌ API: Exception updateMenu: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprimer un menu
  Future<bool> deleteMenu(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/menus/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('❌ Erreur suppression menu: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception suppression menu: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ===== GESTION DES IMAGES =====
  
  /// Supprimer une image de restaurant
  Future<bool> deleteRestaurantImage(int restaurantId, int imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/images/restaurant/$restaurantId/$imageId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprimer une image de menu
  Future<bool> deleteMenuImage(int menuId, int imageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/images/menu/$menuId/$imageId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Définir une image comme principale pour un restaurant
  Future<bool> setRestaurantPrimaryImage(int restaurantId, int imageId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/images/restaurant/$restaurantId/$imageId/primary'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Définir une image comme principale pour un menu
  Future<bool> setMenuPrimaryImage(int menuId, int imageId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/images/menu/$menuId/$imageId/primary'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ===== MÉTHODES POUR LES COMMANDES =====

  /// Créer une nouvelle commande
  Future<Commande> createCommande({
    required int restaurantId,
    required List<CartItem> items,
    double tvaRate = 20.0,
    String currency = 'EUR',
    String? token,
  }) async {
    try {
      print('🛒 [ApiService] Création d\'une commande pour le restaurant $restaurantId');
      print('🔑 [ApiService] Token: ${token != null ? 'Présent' : 'Absent'}');
      
      // Envoyer seulement les menuId et quantités - les prix seront récupérés côté backend
      final commandeItems = items.map((item) => {
        'menuId': item.menu.id,
        'quantite': item.quantite,
      }).toList();
      
      final body = {
        'restaurantId': restaurantId,
        'items': commandeItems,
        'tvaRate': tvaRate,
        'currency': currency,
      };

      // Ajouter le token si fourni - le userId sera extrait du token côté backend
      if (token != null) {
        body['token'] = token;
      }

      print('📤 [ApiService] Corps de la requête: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/commandes'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      print('📡 [ApiService] Statut de réponse: ${response.statusCode}');
      print('📄 [ApiService] Corps de réponse: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final commande = Commande.fromJson(jsonData);
        print('✅ [ApiService] Commande créée avec succès: ID ${commande.id}');
        return commande;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur lors de la création de la commande: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ [ApiService] Erreur lors de la création de la commande: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer une commande par son ID
  Future<Commande> getCommandeById(int commandeId, {String? token}) async {
    try {
      print('🔍 [ApiService] Récupération de la commande $commandeId');
      
      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/commandes/$commandeId'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('📡 [ApiService] Statut de réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final commande = Commande.fromJson(jsonData);
        print('✅ [ApiService] Commande récupérée: ${commande.id}');
        return commande;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur lors de la récupération de la commande: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ [ApiService] Erreur lors de la récupération de la commande: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer toutes les commandes (admin uniquement)
  Future<List<Commande>> getAllCommandes({String? token}) async {
    try {
      print('📋 [ApiService] Récupération de toutes les commandes');
      
      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/commandes'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('📡 [ApiService] Statut de réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Commande> commandes = jsonData
            .map((data) => Commande.fromJson(data as Map<String, dynamic>))
            .toList();
        print('✅ [ApiService] ${commandes.length} commandes récupérées');
        return commandes;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur lors de la récupération des commandes: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ [ApiService] Erreur lors de la récupération des commandes: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer les commandes d'un utilisateur
  Future<List<Commande>> getUserCommandes({
    required int userId,
    String? token,
  }) async {
    try {
      print('📋 [ApiService] Récupération des commandes de l\'utilisateur $userId');
      
      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/commandes/user/$userId'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('📡 [ApiService] Statut de réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Commande> commandes = (data['commandes'] as List)
            .map((item) => Commande.fromJson(item as Map<String, dynamic>))
            .toList();
        print('✅ [ApiService] ${commandes.length} commandes récupérées pour l\'utilisateur $userId');
        return commandes;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur lors de la récupération des commandes: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ [ApiService] Erreur lors de la récupération des commandes: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Remplacer les items d'une commande
  Future<Commande> replaceCommandeItems({
    required int commandeId,
    required List<CartItem> items,
    double? tvaRate,
  }) async {
    try {
      print('🔄 [ApiService] Remplacement des items de la commande $commandeId');
      
      // Convertir les CartItem en format attendu par le backend
      final commandeItems = items.map((item) => item.toCommandeItemJson()).toList();
      
      final body = {
        'items': commandeItems,
        if (tvaRate != null) 'tvaRate': tvaRate,
      };

      print('📤 [ApiService] Corps de la requête: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/commandes/items/$commandeId'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      print('📡 [ApiService] Statut de réponse: ${response.statusCode}');
      print('📄 [ApiService] Corps de réponse: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final commande = Commande.fromJson(jsonData);
        print('✅ [ApiService] Items de la commande remplacés: ID ${commande.id}');
        return commande;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur lors du remplacement des items: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ [ApiService] Erreur lors du remplacement des items: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour le statut d'une commande
  Future<Commande> updateCommandeStatut({
    required int commandeId,
    required String statut,
    String? token,
  }) async {
    try {
      print('📊 [ApiService] Mise à jour du statut de la commande $commandeId: $statut');
      
      final body = {
        'statut': statut,
        if (token != null) 'token': token,
      };

      print('📤 [ApiService] Corps de la requête: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/commandes/statut/$commandeId'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('📡 [ApiService] Statut de réponse: ${response.statusCode}');
      print('📄 [ApiService] Corps de réponse: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final commande = Commande.fromJson(jsonData);
        print('✅ [ApiService] Statut de la commande mis à jour: ${commande.statut}');
        return commande;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur lors de la mise à jour du statut: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ [ApiService] Erreur lors de la mise à jour du statut: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}
