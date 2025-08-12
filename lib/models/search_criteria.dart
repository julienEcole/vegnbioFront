class MenuSearchCriteria {
  final String? titre;
  final int? restaurantId;
  final List<String> allergenesExclus;
  final List<String> allergenesInclus;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  MenuSearchCriteria({
    this.titre,
    this.restaurantId,
    this.allergenesExclus = const [],
    this.allergenesInclus = const [],
    this.dateDebut,
    this.dateFin,
  });

  // Copie avec modifications
  MenuSearchCriteria copyWith({
    String? titre,
    int? restaurantId,
    List<String>? allergenesExclus,
    List<String>? allergenesInclus,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    return MenuSearchCriteria(
      titre: titre ?? this.titre,
      restaurantId: restaurantId ?? this.restaurantId,
      allergenesExclus: allergenesExclus ?? this.allergenesExclus,
      allergenesInclus: allergenesInclus ?? this.allergenesInclus,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
    );
  }

  // Vérifier si les critères sont vides
  bool get isEmpty =>
      (titre?.isEmpty ?? true) &&
      restaurantId == null &&
      allergenesExclus.isEmpty &&
      allergenesInclus.isEmpty &&
      dateDebut == null &&
      dateFin == null;

  // Réinitialiser tous les critères
  MenuSearchCriteria clear() {
    return MenuSearchCriteria();
  }

  // Ajouter un allergène à exclure
  MenuSearchCriteria addAllergeneExclu(String allergene) {
    if (allergenesExclus.contains(allergene)) return this;
    return copyWith(
      allergenesExclus: [...allergenesExclus, allergene],
    );
  }

  // Retirer un allergène à exclure
  MenuSearchCriteria removeAllergeneExclu(String allergene) {
    return copyWith(
      allergenesExclus: allergenesExclus.where((a) => a != allergene).toList(),
    );
  }

  // Ajouter un allergène à inclure
  MenuSearchCriteria addAllergeneInclus(String allergene) {
    if (allergenesInclus.contains(allergene)) return this;
    return copyWith(
      allergenesInclus: [...allergenesInclus, allergene],
    );
  }

  // Retirer un allergène à inclure
  MenuSearchCriteria removeAllergeneInclus(String allergene) {
    return copyWith(
      allergenesInclus: allergenesInclus.where((a) => a != allergene).toList(),
    );
  }

  @override
  String toString() {
    return 'MenuSearchCriteria(titre: $titre, restaurantId: $restaurantId, '
           'allergenesExclus: $allergenesExclus, allergenesInclus: $allergenesInclus, '
           'dateDebut: $dateDebut, dateFin: $dateFin)';
  }
}

// Liste des allergènes les plus courants
class CommonAllergenes {
  static const List<String> all = [
    'gluten',
    'lactose',
    'œufs',
    'soja',
    'arachides',
    'fruits à coque',
    'poisson',
    'crustacés',
    'mollusques',
    'céleri',
    'moutarde',
    'graines de sésame',
    'anhydride sulfureux',
    'lupin',
  ];

  static const Map<String, String> descriptions = {
    'gluten': 'Blé, orge, avoine, seigle',
    'lactose': 'Lait et produits laitiers',
    'œufs': 'Œufs et produits à base d\'œufs',
    'soja': 'Soja et produits à base de soja',
    'arachides': 'Cacahuètes',
    'fruits à coque': 'Amandes, noisettes, noix...',
    'poisson': 'Poissons et produits à base de poisson',
    'crustacés': 'Crevettes, crabes, homards...',
    'mollusques': 'Huîtres, moules, escargots...',
    'céleri': 'Céleri et produits à base de céleri',
    'moutarde': 'Moutarde et produits à base de moutarde',
    'graines de sésame': 'Sésame et produits à base de sésame',
    'anhydride sulfureux': 'Conservateur E220-E228',
    'lupin': 'Légumineuse proche du pois chiche',
  };
}
