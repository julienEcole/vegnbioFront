import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commande.model.dart';
import 'api_service.dart';

class CommandeService {
  static String get _baseUrl => '${ApiService.baseUrl}/commandes';

  /// Récupérer les commandes d'un utilisateur
  static Future<Map<String, dynamic>> getUserCommandes({
    required int userId,
    String? status,
    int limit = 50,
    int offset = 0,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/user/$userId').replace(
        queryParameters: queryParams,
      );

      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commandes': (data['commandes'] as List)
              .map((json) => Commande.fromJson(json))
              .toList(),
          'total': data['total'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la récupération des commandes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer les commandes d'un restaurant
  static Future<Map<String, dynamic>> getRestaurantCommandes({
    required int restaurantId,
    String? status,
    int? menuId,
    int limit = 50,
    int offset = 0,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      if (menuId != null) {
        queryParams['menuId'] = menuId.toString();
      }

      final uri = Uri.parse('$_baseUrl/restaurant/$restaurantId').replace(
        queryParameters: queryParams,
      );

      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commandes': (data['commandes'] as List)
              .map((json) => Commande.fromJson(json))
              .toList(),
          'total': data['total'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la récupération des commandes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer les commandes de tous les restaurants (chaîne)
  static Future<Map<String, dynamic>> getAllRestaurantsCommandes({
    String? status,
    int? menuId,
    int limit = 50,
    int offset = 0,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      if (menuId != null) {
        queryParams['menuId'] = menuId.toString();
      }

      final uri = Uri.parse('$_baseUrl/restaurants').replace(
        queryParameters: queryParams,
      );

      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commandes': (data['commandes'] as List)
              .map((json) => Commande.fromJson(json))
              .toList(),
          'total': data['total'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la récupération des commandes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer une commande par ID
  static Future<Map<String, dynamic>> getCommandeById({
    required int commandeId,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$commandeId');

      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commande': Commande.fromJson(data),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la récupération de la commande',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Mettre à jour le statut d'une commande
  static Future<Map<String, dynamic>> updateStatut({
    required int commandeId,
    required String statut,
    String? notes,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/statut/$commandeId');

      final body = {
        'statut': statut,
        if (notes != null) 'notes': notes,
        if (token != null) 'token': token,
      };

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commande': Commande.fromJson(data),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la mise à jour du statut',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Vérifier le paiement avec Stripe
  static Future<Map<String, dynamic>> verifyPayment({
    required int commandeId,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$commandeId/verify-payment');

      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'isValid': data['isValid'],
          'details': data['details'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la vérification du paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Marquer une commande comme suspecte
  static Future<Map<String, dynamic>> markAsSuspicious({
    required int commandeId,
    required String reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$commandeId/mark-suspicious');

      final body = {
        'reason': reason,
        if (token != null) 'token': token,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commande': Commande.fromJson(data),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du marquage suspect',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Annuler une commande
  static Future<Map<String, dynamic>> cancelCommande({
    required int commandeId,
    String? reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$commandeId/cancel');

      final body = <String, dynamic>{};
      if (reason != null) {
        body['reason'] = reason;
      }
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commande': Commande.fromJson(data),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de l\'annulation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Demander un remboursement (admin uniquement)
  static Future<Map<String, dynamic>> requestRefund({
    required int commandeId,
    String? reason,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$commandeId/refund');

      final body = <String, dynamic>{};
      if (reason != null) {
        body['reason'] = reason;
      }
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'refundId': data['refundId'],
          'commande': Commande.fromJson(data['commande']),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du remboursement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Finaliser le paiement d'une commande avec les informations Stripe
  static Future<Map<String, dynamic>> completePayment({
    required int commandeId,
    required String paymentIntentId,
    required String paymentMethodId,
    required double amount,
    required String currency,
    String? cardBrand,
    String? cardLast4,
    Map<String, dynamic>? deliveryInfo,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$commandeId/complete-payment');

      final body = <String, dynamic>{
        'paymentInfo': {
          'paymentIntentId': paymentIntentId,
          'paymentMethodId': paymentMethodId,
          'amount': (amount * 100).round(), // Convertir en centimes
          'currency': currency,
          'status': 'succeeded',
          'cardBrand': cardBrand,
          'cardLast4': cardLast4,
          'paidAt': DateTime.now().toIso8601String(),
        },
      };

      if (deliveryInfo != null) {
        body['deliveryInfo'] = deliveryInfo;
      }

      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'commande': Commande.fromJson(data),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la finalisation du paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer les statistiques des commandes
  static Future<Map<String, dynamic>> getOrderStatistics({
    int? restaurantId,
    DateTime? startDate,
    DateTime? endDate,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final path = restaurantId != null 
          ? '$_baseUrl/statistics/$restaurantId'
          : '$_baseUrl/statistics';
      
      final uri = Uri.parse(path).replace(queryParameters: queryParams);

      final body = <String, dynamic>{};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'statistics': data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la récupération des statistiques',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }
}
