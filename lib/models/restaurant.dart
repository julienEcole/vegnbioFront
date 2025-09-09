import 'restaurant_image.dart';

class Restaurant {
  final int id;
  final String nom;
  final String quartier;
  final String? adresse;
  final List<RestaurantImage>? images; // Images multiples via relation 0 à n
  final int imagesCount; // Nombre total d'images
  final List<Horaire>? horaires;
  final List<Equipement>? equipements;

  Restaurant({
    required this.id,
    required this.nom,
    required this.quartier,
    this.adresse,
    this.images,
    this.imagesCount = 0,
    this.horaires,
    this.equipements,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nom: json['nom']?.toString() ?? '',
      quartier: json['quartier']?.toString() ?? '',
      adresse: json['adresse']?.toString(),
      images: json['images'] != null
          ? (json['images'] as List)
              .map((img) => RestaurantImage.fromJson(img as Map<String, dynamic>))
              .toList()
          : null,
      imagesCount: json['imagesCount'] ?? json['images_count'] ?? 0,
      horaires: json['horaires'] != null
          ? (json['horaires'] as List)
              .map((h) => Horaire.fromJson(h as Map<String, dynamic>))
              .toList()
          : null,
      equipements: json['equipements'] != null
          ? (json['equipements'] as List)
              .map((e) => Equipement.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'quartier': quartier,
      'adresse': adresse,
      'images': images?.map((img) => img.toJson()).toList(),
      'imagesCount': imagesCount,
      'horaires': horaires?.map((h) => h.toJson()).toList(),
      'equipements': equipements?.map((e) => e.toJson()).toList(),
    };
  }

  /// Retourne l'image principale ou null si aucune image
  String? get primaryImageUrl {
    if (images != null && images!.isNotEmpty) {
      final primaryImage = images!.firstWhere(
        (img) => img.isPrimary,
        orElse: () => images!.first,
      );
      return primaryImage.imageUrl;
    }
    return null; // Plus de fallback vers l'ancien système
  }

  /// Retourne toutes les images ou une liste vide
  List<RestaurantImage> get allImages {
    return images ?? [];
  }

  /// Vérifie si le restaurant a des images
  bool get hasImages {
    return images != null && images!.isNotEmpty;
  }
}

class Horaire {
  final int id;
  final int restaurantId;
  final String jour;
  final String ouverture;
  final String fermeture;

  Horaire({
    required this.id,
    required this.restaurantId,
    required this.jour,
    required this.ouverture,
    required this.fermeture,
  });

  factory Horaire.fromJson(Map<String, dynamic> json) {
    // Gestion robuste des types avec fallbacks
    final id = json['id'];
    final restaurantId = json['restaurantId'];
    final jour = json['jour'];
    final ouverture = json['ouverture'];
    final fermeture = json['fermeture'];

    return Horaire(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()) ?? 0,
      jour: jour?.toString() ?? '',
      ouverture: ouverture != null ? ouverture.toString().substring(0, 5) : '00:00',
      fermeture: fermeture != null ? fermeture.toString().substring(0, 5) : '00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'jour': jour,
      'ouverture': ouverture,
      'fermeture': fermeture,
    };
  }
}

class Equipement {
  final int id;
  final String nom;
  final RestaurantEquipement? restaurantEquipement;

  Equipement({
    required this.id,
    required this.nom,
    this.restaurantEquipement,
  });

  factory Equipement.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nom = json['nom'];
    
    return Equipement(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      nom: nom?.toString() ?? '',
      restaurantEquipement: json['RestaurantEquipement'] != null
          ? RestaurantEquipement.fromJson(json['RestaurantEquipement'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      if (restaurantEquipement != null)
        'RestaurantEquipement': restaurantEquipement!.toJson(),
    };
  }
}

class RestaurantEquipement {
  final int id;
  final int restaurantId;
  final int equipementId;

  RestaurantEquipement({
    required this.id,
    required this.restaurantId,
    required this.equipementId,
  });

  factory RestaurantEquipement.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final restaurantId = json['restaurantId'];
    final equipementId = json['equipementId'];
    
    return RestaurantEquipement(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()) ?? 0,
      equipementId: equipementId is int ? equipementId : int.tryParse(equipementId.toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'equipementId': equipementId,
    };
  }
}
