// Placez ce fichier dans : lib/models/reservation_model.dart

/// Modèle pour créer une réservation
class ReservationRequest {
  final int places;
  final String contactPhone;
  final String? notes;

  ReservationRequest({
    required this.places,
    required this.contactPhone,
    this.notes,
  });

  /// Conversion en JSON pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      'places': places,
      'contactPhone': contactPhone,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

/// Modèle pour la réponse de réservation
class Reservation {
  final int id;
  final int eventId;
  final int places;
  final String contactPhone;
  final String? notes;
  final String statut;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.eventId,
    required this.places,
    required this.contactPhone,
    this.notes,
    required this.statut,
    required this.createdAt,
  });

  /// Création d'une Reservation depuis JSON
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      places: json['places'] as int,
      contactPhone: json['contactPhone'] as String,
      notes: json['notes'] as String?,
      statut: json['statut'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}