class Menu {
  final int id;
  final String titre;
  final String? description;
  final DateTime date;
  final List<String> allergenes;
  final int restaurantId;
  final String? imageUrl; // Gardé pour l'instant, sera remplacé par le système d'images

  Menu({
    required this.id,
    required this.titre,
    this.description,
    required this.date,
    required this.allergenes,
    required this.restaurantId,
    this.imageUrl,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final titre = json['titre'];
    final description = json['description'];
    final date = json['date'];
    final allergenes = json['allergenes'];
    final restaurantId = json['restaurant_id'] ?? json['restaurantId']; // Support des deux formats
    final imageUrl = json['imageUrl'] ?? json['image_url']; // Support des deux formats
    
    return Menu(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      titre: titre?.toString() ?? '',
      description: description?.toString(),
      date: _parseDate(date),
      allergenes: _parseAllergenes(allergenes),
      restaurantId: restaurantId is int ? restaurantId : int.tryParse(restaurantId.toString()) ?? 0,
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
      print('Erreur parsing date: $e, valeur: $dateValue');
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
      print('Erreur parsing allergènes: $e, valeur: $allergenesValue');
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
      'restaurant_id': restaurantId,
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
}
