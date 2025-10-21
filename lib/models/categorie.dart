// lib/models/categorie.dart
class Categorie {
  final int id;
  final String nom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Categorie({
    required this.id,
    required this.nom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'] as int,
      nom: json['nom'] as String,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

/// Payload minimal pour créer une catégorie
class CategorieCreateRequest {
  final String nom;
  CategorieCreateRequest(this.nom);

  Map<String, dynamic> toJson() => {'nom': nom};
}
