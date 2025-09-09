import 'menu.dart';

class PanierItem {
  final int menuId;
  final String nom;
  final double prix;
  final String? imageUrl;
  final String? description;
  int quantite;
  final Map<String, dynamic>? options; // Pour les options personnalisées

  PanierItem({
    required this.menuId,
    required this.nom,
    required this.prix,
    this.imageUrl,
    this.description,
    this.quantite = 1,
    this.options,
  });

  // Créer un PanierItem à partir d'un Menu
  factory PanierItem.fromMenu(Menu menu, {int quantite = 1}) {
    return PanierItem(
      menuId: menu.id,
      nom: menu.titre,
      prix: menu.prix,
      imageUrl: menu.imageUrl,
      description: menu.description,
      quantite: quantite,
    );
  }

  // Calculer le total de cette ligne
  double get totalLigne => prix * quantite;

  // Méthodes utilitaires
  String get prixText => '${prix.toStringAsFixed(2)} €';
  String get totalLigneText => '${totalLigne.toStringAsFixed(2)} €';

  // Modifier la quantité
  PanierItem copyWithQuantite(int nouvelleQuantite) {
    return PanierItem(
      menuId: menuId,
      nom: nom,
      prix: prix,
      imageUrl: imageUrl,
      description: description,
      quantite: nouvelleQuantite,
      options: options,
    );
  }

  // Convertir en CommandeItem pour l'API
  Map<String, dynamic> toCommandeItemJson() {
    return {
      'menu_id': menuId,
      'nom': nom,
      'prixUnitaire': prix,
      'quantite': quantite,
      'totalLigne': totalLigne,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PanierItem &&
        other.menuId == menuId &&
        other.options == options;
  }

  @override
  int get hashCode => menuId.hashCode ^ options.hashCode;
}
