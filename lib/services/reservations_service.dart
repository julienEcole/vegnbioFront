// Placez ce fichier dans : lib/services/reservations_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vegnbio_front/models/reservation_model.dart';
import 'package:vegnbio_front/services/auth/real_auth_service.dart';
import '../config/app_config.dart';

/// Service pour gérer les réservations d'événements
class ReservationsService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/reservations';
  final RealAuthService _authService = RealAuthService();

  /// Obtenir les headers avec authentification
  Map<String, String> get _authHeaders {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Ajouter le token Bearer si disponible
    if (_authService.token != null) {
      headers['Authorization'] = 'Bearer ${_authService.token}';
    }

    return headers;
  }

  /// Crée une réservation pour un événement
  Future<Reservation> createReservation(
      int eventId,
      ReservationRequest request,
      ) async {
    // print('📝 [ReservationsService] Création réservation pour événement $eventId');
    // print('🔑 [ReservationsService] Token présent: ${_authService.token != null}');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/evenements/$eventId/reservations'),
        headers: _authHeaders,
        body: json.encode(request.toJson()),
      );

      // print('📡 [ReservationsService] Statut: ${response.statusCode}');
      // print('📄 [ReservationsService] Réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Reservation.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Données invalides');
      } else if (response.statusCode == 404) {
        throw Exception('Événement introuvable');
      } else if (response.statusCode == 409) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Conflit de réservation');
      } else {
        throw Exception(
          'Erreur lors de la réservation: ${response.statusCode}',
        );
      }
    } catch (e) {
      // print('❌ [ReservationsService] Erreur: $e');
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les réservations d'un événement
  Future<List<Reservation>> getEventReservations(int eventId) async {
    // print('📋 [ReservationsService] Récupération réservations événement $eventId');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evenements/$eventId/reservations'),
        headers: _authHeaders,
      );

      // print('📡 [ReservationsService] Statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Reservation.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else {
        throw Exception(
          'Erreur lors du chargement des réservations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // print('❌ [ReservationsService] Erreur: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les réservations de l'utilisateur connecté
  Future<List<Reservation>> getMyReservations() async {
    // print('📋 [ReservationsService] Récupération de mes réservations');

    if (_authService.token == null) {
      throw Exception('Vous devez être connecté pour voir vos réservations');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mes-reservations'),
        headers: _authHeaders,
      );

      // print('📡 [ReservationsService] Statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Reservation.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else {
        throw Exception(
          'Erreur lors du chargement de vos réservations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // print('❌ [ReservationsService] Erreur: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Annule une réservation
  Future<bool> cancelReservation(int reservationId) async {
    // print('🗑️ [ReservationsService] Annulation réservation $reservationId');

    if (_authService.token == null) {
      throw Exception('Vous devez être connecté pour annuler une réservation');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$reservationId'),
        headers: _authHeaders,
      );

      // print('📡 [ReservationsService] Statut: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous connecter.');
      } else if (response.statusCode == 404) {
        throw Exception('Réservation introuvable');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      // print('❌ [ReservationsService] Erreur: $e');
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion: $e');
    }
  }
}