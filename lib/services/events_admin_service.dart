// Placez ce fichier dans : lib/services/events_admin_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vegnbio_front/models/event_model.dart';
import 'package:vegnbio_front/services/auth/real_auth_service.dart';
/// Service d'administration des événements (CRUD complet)
class EventsAdminService {
  static const String baseUrl = 'http://localhost:3001/api/evenements';
  final RealAuthService _authService = RealAuthService();

  /// Obtenir les headers avec authentification
  Map<String, String> get _authHeaders {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authService.token != null) {
      headers['Authorization'] = 'Bearer ${_authService.token}';
    }

    return headers;
  }

  /// Récupère tous les événements (admin)
  Future<List<Event>> getAllEvents() async {
    print('📋 [EventsAdminService] Récupération de tous les événements');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/evenements'),
        headers: _authHeaders,
      );

      print('📡 [EventsAdminService] Statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Event.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else {
        throw Exception('Erreur lors du chargement: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EventsAdminService] Erreur: $e');
      rethrow;
    }
  }

  /// Récupère un événement par son ID
  Future<Event> getEventById(int id) async {
    print('🔍 [EventsAdminService] Récupération événement $id');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$id'),
        headers: _authHeaders,
      );

      print('📡 [EventsAdminService] Statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Événement introuvable');
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else {
        throw Exception('Erreur lors du chargement: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EventsAdminService] Erreur: $e');
      rethrow;
    }
  }

  /// Crée un nouvel événement
  Future<Event> createEvent({
    required int restaurantId,
    required String titre,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
    required bool isPublic,
    String? imageUrl,
  }) async {
    print('➕ [EventsAdminService] Création d\'un événement');

    if (_authService.token == null) {
      throw Exception('Vous devez être connecté pour créer un événement');
    }

    try {
      final body = {
        'restaurantId': restaurantId,
        'titre': titre,
        'description': description,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'capacity': capacity,
        'isPublic': isPublic,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      print('📤 [EventsAdminService] Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/evenements'),
        headers: _authHeaders,
        body: json.encode(body),
      );

      print('📡 [EventsAdminService] Statut: ${response.statusCode}');
      print('📄 [EventsAdminService] Réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Event.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Données invalides');
      } else {
        throw Exception('Erreur lors de la création: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EventsAdminService] Erreur: $e');
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Met à jour un événement existant
  Future<Event> updateEvent({
    required int id,
    String? titre,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    int? capacity,
    bool? isPublic,
    String? imageUrl,
  }) async {
    print('✏️ [EventsAdminService] Mise à jour événement $id');

    if (_authService.token == null) {
      throw Exception('Vous devez être connecté pour modifier un événement');
    }

    try {
      final body = <String, dynamic>{};

      if (titre != null) body['titre'] = titre;
      if (description != null) body['description'] = description;
      if (startAt != null) body['startAt'] = startAt.toIso8601String();
      if (endAt != null) body['endAt'] = endAt.toIso8601String();
      if (capacity != null) body['capacity'] = capacity;
      if (isPublic != null) body['isPublic'] = isPublic;
      if (imageUrl != null) body['imageUrl'] = imageUrl;

      print('📤 [EventsAdminService] Body: ${json.encode(body)}');

      final response = await http.patch(
        Uri.parse('$baseUrl/evenements/$id'),
        headers: _authHeaders,
        body: json.encode(body),
      );

      print('📡 [EventsAdminService] Statut: ${response.statusCode}');
      print('📄 [EventsAdminService] Réponse: ${response.body}');

      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else if (response.statusCode == 404) {
        throw Exception('Événement introuvable');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Données invalides');
      } else {
        throw Exception('Erreur lors de la mise à jour: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EventsAdminService] Erreur: $e');
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprime un événement
  Future<bool> deleteEvent(int id) async {
    print('🗑️ [EventsAdminService] Suppression événement $id');

    if (_authService.token == null) {
      throw Exception('Vous devez être connecté pour supprimer un événement');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$id'),
        headers: _authHeaders,
      );

      print('📡 [EventsAdminService] Statut: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else if (response.statusCode == 404) {
        throw Exception('Événement introuvable');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      print('❌ [EventsAdminService] Erreur: $e');
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion: $e');
    }
  }
}