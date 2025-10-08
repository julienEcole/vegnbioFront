// models/offre.dart
class Offre {
  final int id;
  final int userId;
  final String titre;
  final String? description;
  final String prix;       // DECIMAL côté SQL → string en JSON
  final int quantite;
  final String unite;
  final int? categorieId;
  final bool disponible;
  final DateTime createdAt;
  final DateTime updatedAt;

  Offre({
    required this.id,
    required this.userId,
    required this.titre,
    this.description,
    required this.prix,
    required this.quantite,
    required this.unite,
    this.categorieId,
    required this.disponible,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offre.fromJson(Map<String, dynamic> j) => Offre(
    id: j['id'] as int,
    userId: j['userId'] as int,              // back : "userId"
    titre: j['titre'] as String,
    description: j['description'] as String?,
    prix: j['prix'].toString(),
    quantite: j['quantite'] as int,
    unite: j['unite'] as String,
    categorieId: j['categorieId'] as int?,
    disponible: (j['disponible'] as bool?) ?? true,
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'titre': titre,
    'description': description,
    'prix': prix,
    'quantite': quantite,
    'unite': unite,
    'categorieId': categorieId,
    'disponible': disponible,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
