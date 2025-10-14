// Placez ce fichier dans : lib/services/events_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vegnbio_front/models/event_model.dart';
import '../config/app_config.dart';

/// Service pour gérer les appels API liés aux événements
class EventsService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/evenements';

  /// Récupère tous les événements publics
  Future<List<Event>> fetchPublicEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/evenements'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception(
          'Erreur lors du chargement des événements: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère un événement spécifique par son ID
  Future<Event> fetchEventById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/evenements/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Erreur lors du chargement de l\'événement: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}