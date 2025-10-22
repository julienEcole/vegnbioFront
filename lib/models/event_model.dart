// Placez ce fichier dans : lib/models/event_model.dart

/// Modèle pour représenter un événement
class Event {
  final int id;
  final int restaurantId;
  final int createdBy;
  final int? salleId;
  final String titre;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final int capacity;
  final bool isPublic;
  final String statut;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? capacityTotal;
  final int? reservedPlaces;
  final int? capacityRemaining;

  Event({
    required this.id,
    required this.restaurantId,
    required this.createdBy,
    this.salleId,
    required this.titre,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.isPublic,
    required this.statut,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.capacityTotal,
    this.reservedPlaces,
    this.capacityRemaining,
  });

  /// Création d'un Event depuis JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      restaurantId: json['restaurantId'] as int,
      createdBy: json['createdBy'] as int,
      salleId: json['salleId'] as int?,
      titre: json['titre'] as String,
      description: json['description'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      capacity: json['capacity'] as int,
      isPublic: json['isPublic'] as bool,
      statut: json['statut'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      capacityTotal: json['capacityTotal'] as int?,
      reservedPlaces: json['reservedPlaces'] as int?,
      capacityRemaining: json['capacityRemaining'] as int?,
    );
  }

  /// Conversion d'un Event en JSON
  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'restaurantId': restaurantId,
      'createdBy': createdBy,
      'salleId': salleId,
      'titre': titre,
      'description': description,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'capacity': capacity,
      'isPublic': isPublic,
      'statut': statut,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (capacityTotal != null) map['capacityTotal'] = capacityTotal;
    if (reservedPlaces != null) map['reservedPlaces'] = reservedPlaces;
    if (capacityRemaining != null) map['capacityRemaining'] = capacityRemaining;
    return map;
  }
}