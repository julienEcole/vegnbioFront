class CommandeItem {
  final int? id;
  final int? commandeId;
  final int? menuId;
  final String nom;
  final double prixUnitaire;
  final int quantite;
  final double totalLigne;

  CommandeItem({
    this.id,
    this.commandeId,
    this.menuId,
    required this.nom,
    required this.prixUnitaire,
    required this.quantite,
    required this.totalLigne,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      id: json['id'],
      commandeId: json['commandeId'],
      menuId: json['menuId'],
      nom: json['nom'] ?? '',
      prixUnitaire: _parseDouble(json['prixUnitaire'] ?? 0),
      quantite: json['quantite'] ?? 1,
      totalLigne: _parseDouble(json['totalLigne'] ?? 0),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commandeId': commandeId,
      'menuId': menuId,
      'nom': nom,
      'prixUnitaire': prixUnitaire,
      'quantite': quantite,
      'totalLigne': totalLigne,
    };
  }

  CommandeItem copyWith({
    int? id,
    int? commandeId,
    int? menuId,
    String? nom,
    double? prixUnitaire,
    int? quantite,
    double? totalLigne,
  }) {
    return CommandeItem(
      id: id ?? this.id,
      commandeId: commandeId ?? this.commandeId,
      menuId: menuId ?? this.menuId,
      nom: nom ?? this.nom,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      quantite: quantite ?? this.quantite,
      totalLigne: totalLigne ?? this.totalLigne,
    );
  }

  @override
  String toString() {
    return 'CommandeItem(id: $id, commandeId: $commandeId, menuId: $menuId, nom: $nom, prixUnitaire: $prixUnitaire, quantite: $quantite, totalLigne: $totalLigne)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommandeItem &&
        other.id == id &&
        other.commandeId == commandeId &&
        other.menuId == menuId &&
        other.nom == nom &&
        other.prixUnitaire == prixUnitaire &&
        other.quantite == quantite &&
        other.totalLigne == totalLigne;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        commandeId.hashCode ^
        menuId.hashCode ^
        nom.hashCode ^
        prixUnitaire.hashCode ^
        quantite.hashCode ^
        totalLigne.hashCode;
  }
}
