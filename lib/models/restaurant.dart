class Restaurant {
  final int id;
  final String nom;
  final String quartier;
  final String? adresse;
  final List<Horaire>? horaires;
  final List<Equipement>? equipements;

  Restaurant({
    required this.id,
    required this.nom,
    required this.quartier,
    this.adresse,
    this.horaires,
    this.equipements,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nom = json['nom'];
    final quartier = json['quartier'];
    final adresse = json['adresse'];
    
    return Restaurant(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      nom: nom?.toString() ?? '',
      quartier: quartier?.toString() ?? '',
      adresse: adresse?.toString(),
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
      'horaires': horaires?.map((h) => h.toJson()).toList(),
      'equipements': equipements?.map((e) => e.toJson()).toList(),
    };
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
