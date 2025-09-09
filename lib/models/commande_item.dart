class CommandeItem {
  final int id;
  final int commandeId;
  final int? menuId;
  final String nom;
  final double prixUnitaire;
  final int quantite;
  final double totalLigne;

  CommandeItem({
    required this.id,
    required this.commandeId,
    this.menuId,
    required this.nom,
    required this.prixUnitaire,
    required this.quantite,
    required this.totalLigne,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      id: json['id'],
      commandeId: json['commande_id'],
      menuId: json['menu_id'],
      nom: json['nom'],
      prixUnitaire: (json['prixUnitaire'] ?? 0).toDouble(),
      quantite: json['quantite'] ?? 1,
      totalLigne: (json['totalLigne'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'menu_id': menuId,
      'nom': nom,
      'prixUnitaire': prixUnitaire,
      'quantite': quantite,
      'totalLigne': totalLigne,
    };
  }

  // Méthodes utilitaires
  String get prixText => '${prixUnitaire.toStringAsFixed(2)} €';
  String get totalLigneText => '${totalLigne.toStringAsFixed(2)} €';
  
  // Créer un nouvel item pour une commande
  factory CommandeItem.create({
    required int commandeId,
    int? menuId,
    required String nom,
    required double prixUnitaire,
    int quantite = 1,
  }) {
    return CommandeItem(
      id: 0, // sera assigné par le backend
      commandeId: commandeId,
      menuId: menuId,
      nom: nom,
      prixUnitaire: prixUnitaire,
      quantite: quantite,
      totalLigne: prixUnitaire * quantite,
    );
  }

  // Modifier la quantité
  CommandeItem copyWithQuantite(int nouvelleQuantite) {
    return CommandeItem(
      id: id,
      commandeId: commandeId,
      menuId: menuId,
      nom: nom,
      prixUnitaire: prixUnitaire,
      quantite: nouvelleQuantite,
      totalLigne: prixUnitaire * nouvelleQuantite,
    );
  }
}
