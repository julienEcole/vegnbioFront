import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UserDeletionService {
  final String baseUrl = AppConfig.apiBaseUrl;

  /// Obtenir les statistiques des données utilisateur avant suppression
  Future<Map<String, dynamic>> getUserDataStats(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/deletion/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Supprimer les données personnelles de l'utilisateur (conserve les commandes payées)
  Future<Map<String, dynamic>> deleteUserData(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/deletion/data'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression des données');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Supprimer complètement le compte utilisateur et toutes ses données
  Future<Map<String, dynamic>> deleteAccount(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/deletion/account'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression du compte');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}

