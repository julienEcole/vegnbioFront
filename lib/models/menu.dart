class Menu {
  final int id;
  final String titre;
  final String? description;
  final DateTime date;
  final List<String> allergenes;
  final List<String> produits;
  final int restaurantId;
  final double prix;
  final bool disponible;
  final String? imageUrl; // Gardé pour l'instant, sera remplacé par le système d'images

  Menu({
    required this.id,
    required this.titre,
    this.description,
    required this.date,
    required this.allergenes,
    required this.produits,
    required this.restaurantId,
    required this.prix,
    required this.disponible,
    this.imageUrl,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final titre = json['titre'];
    final description = json['description'];
    final date = json['date'];
    final allergenes = json['allergenes'];
    final produits = json['produits'];
    final restaurantId = json['restaurant_id'] ?? json['restaurantId']; // Support des deux formats
    final prix = json['prix'];
    final disponible = json['disponible'];
    final imageUrl = json['imageUrl'] ?? json['image_url']; // Support des deux formats
    
    return Menu(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      titre: titre?.toString() ?? '',
      description: description?.toString(),
      date: _parseDate(date),
      allergenes: _parseAllergenes(allergenes),
      produits: _parseProduits(produits),
      restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()) ?? 0,
      prix: prix is num ? prix.toDouble() : (prix is String ? double.tryParse(prix) ?? 0.0 : 0.0),
      disponible: disponible is bool ? disponible : true,
      imageUrl: imageUrl?.toString(),
    );
  }

  // Méthode helper pour parser les dates de manière robuste
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      // print('Erreur parsing date: $e, valeur: $dateValue');
    }
    
    return DateTime.now();
  }

  // Méthode helper pour parser les allergènes de manière robuste
  static List<String> _parseAllergenes(dynamic allergenesValue) {
    if (allergenesValue == null) return [];
    
    try {
      if (allergenesValue is List) {
        return allergenesValue.map((e) => e.toString()).toList();
      } else if (allergenesValue is String) {
        // Si c'est une chaîne, on essaie de la parser
        return [allergenesValue];
      }
    } catch (e) {
      // print('Erreur parsing allergènes: $e, valeur: $allergenesValue');
    }
    
    return [];
  }

  // Méthode helper pour parser les produits de manière robuste
  static List<String> _parseProduits(dynamic produitsValue) {
    if (produitsValue == null) return [];
    
    try {
      if (produitsValue is List) {
        return produitsValue.map((e) => e.toString()).toList();
      } else if (produitsValue is String) {
        // Si c'est une chaîne, on essaie de la parser
        return [produitsValue];
      }
    } catch (e) {
      // print('Erreur parsing produits: $e, valeur: $produitsValue');
    }
    
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // Format YYYY-MM-DD
      'allergenes': allergenes,
      'produits': produits,
      'restaurant_id': restaurantId,
      'prix': prix,
      'disponible': disponible,
      'imageUrl': imageUrl,
    };
  }

  String get formattedDate {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get allergenesText {
    if (allergenes.isEmpty) return 'Aucun allergène signalé';
    return 'Allergènes : ${allergenes.join(', ')}';
  }

  String get produitsText {
    if (produits.isEmpty) return 'Aucun produit détaillé';
    return 'Produits : ${produits.join(', ')}';
  }

  String get prixText {
    return '${prix.toStringAsFixed(2)} €';
  }
}
