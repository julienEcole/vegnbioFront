import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offres_service.dart';
import '../providers/offres_provider.dart'; // <-- contient offresServiceProvider

// --- Modèles d'état ---
class MarketFilters {
  final String query;          // recherche par titre / description
  final bool onlyAvailable;    // disponibles uniquement
  final int? categorieId;      // filtre catégorie (si présent dans les données)
  final String sort;           // 'price_asc' | 'price_desc' | 'recent'

  const MarketFilters({
    this.query = '',
    this.onlyAvailable = false,
    this.categorieId,
    this.sort = 'price_asc',
  });

  MarketFilters copyWith({
    String? query,
    bool? onlyAvailable,
    int? categorieId,
    String? sort,
  }) => MarketFilters(
    query: query ?? this.query,
    onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    categorieId: categorieId ?? this.categorieId,
    sort: sort ?? this.sort,
  );
}

class MarketBrowseState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> all;         // offres brutes depuis API (liste complète)
  final List<int> compareIds;                   // sélection pour comparer

  const MarketBrowseState({
    required this.loading,
    this.error,
    required this.all,
    required this.compareIds,
  });

  MarketBrowseState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? all,
    List<int>? compareIds,
  }) => MarketBrowseState(
    loading: loading ?? this.loading,
    error: error,
    all: all ?? this.all,
    compareIds: compareIds ?? this.compareIds,
  );
}

// --- Notifier ---
class MarketBrowseNotifier extends StateNotifier<MarketBrowseState> {
  MarketBrowseNotifier(this.ref)
      : _filters = const MarketFilters(),
        super(const MarketBrowseState(loading: false, all: [], compareIds: []));

  final Ref ref;
  MarketFilters _filters;

  MarketFilters get filters => _filters;

  OffresService get _service => ref.read(offresServiceProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // On ne modifie pas le service : on récupère tout et on filtre côté client
      final data = await _service.listOffres(); // List<Map>
      state = state.copyWith(loading: false, all: data);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // --- Sélection pour comparaison ---
  void toggleCompare(int offreId) {
    final list = List<int>.from(state.compareIds);
    if (list.contains(offreId)) {
      list.remove(offreId);
    } else {
      if (list.length >= 4) return; // limite à 4 offres
      list.add(offreId);
    }
    state = state.copyWith(compareIds: list);
  }

  void clearCompare() => state = state.copyWith(compareIds: []);

  // --- Filtres ---
  void setQuery(String q) {
    _filters = _filters.copyWith(query: q);
    // pas besoin de recharger (filtrage client)
    state = state.copyWith(); // trigger rebuild
  }

  void setOnlyAvailable(bool v) {
    _filters = _filters.copyWith(onlyAvailable: v);
    state = state.copyWith();
  }

  void setCategorieId(int? id) {
    _filters = _filters.copyWith(categorieId: id);
    state = state.copyWith();
  }

  void setSort(String sort) {
    _filters = _filters.copyWith(sort: sort);
    state = state.copyWith();
  }

  // --- Vue filtrée / triée ---
  List<Map<String, dynamic>> get filtered {
    final q = _filters.query.trim().toLowerCase();
    final only = _filters.onlyAvailable;
    final cat = _filters.categorieId;

    List<Map<String, dynamic>> rows = state.all.where((o) {
      final titre = (o['titre'] ?? '').toString().toLowerCase();
      final desc  = (o['description'] ?? '').toString().toLowerCase();
      final dispo = (o['disponible'] == true);

      final catOk = cat == null
          ? true
          : (o['categorieId'] == cat) || (o['categorie']?['id'] == cat);

      final qOk = q.isEmpty || titre.contains(q) || desc.contains(q);
      final dOk = !only || dispo;

      return qOk && dOk && catOk;
    }).toList();

    // tri
    rows.sort((a, b) {
      final pa = _unitPrice(a); // prix/quantité
      final pb = _unitPrice(b);
      switch (_filters.sort) {
        case 'price_desc':
          return pb.compareTo(pa);
        case 'recent':
          final da = DateTime.tryParse((a['createdAt'] ?? a['created_at'] ?? '').toString())?.millisecondsSinceEpoch ?? 0;
          final db = DateTime.tryParse((b['createdAt'] ?? b['created_at'] ?? '').toString())?.millisecondsSinceEpoch ?? 0;
          return db.compareTo(da);
        case 'price_asc':
        default:
          return pa.compareTo(pb);
      }
    });

    return rows;
  }

  // Catégories disponibles (extraites du dataset)
  List<Map<String, dynamic>> get availableCategories {
    final set = <int, Map<String, dynamic>>{};
    for (final o in state.all) {
      final id = o['categorieId'] ?? o['categorie']?['id'];
      final nom = o['categorie']?['nom'];
      if (id is int) {
        set[id] = {'id': id, 'nom': nom ?? 'Catégorie $id'};
      }
    }
    return set.values.toList()
      ..sort((a, b) => (a['nom'] ?? '').toString().compareTo((b['nom'] ?? '').toString()));
  }

  // prix / quantité (double) pour comparaison
  double _unitPrice(Map<String, dynamic> o) {
    final prix = double.tryParse(o['prix']?.toString() ?? '') ?? 0.0;
    final qte  = (o['quantite'] is num) ? (o['quantite'] as num).toDouble() : double.tryParse('${o['quantite']}') ?? 1.0;
    if (qte <= 0) return prix; // fallback
    return prix / qte;
  }

  // tableaux de comparaison (données prêtes à afficher)
  List<Map<String, dynamic>> get compareRows {
    final selected = state.compareIds.toSet();
    final rows = filtered.where((o) => selected.contains(o['id'])).toList();
    rows.sort((a, b) => _unitPrice(a).compareTo(_unitPrice(b)));
    return rows.map((o) => {
      'id': o['id'],
      'titre': o['titre'],
      'fournisseurId': o['userId'],
      'prix': o['prix'],
      'quantite': o['quantite'],
      'unite': o['unite'],
      'disponible': o['disponible'] == true,
      'categorie': o['categorie']?['nom'],
      'ppu': _unitPrice(o), // prix par unité
    }).toList();
  }
}

// Provider global
final marketBrowseProvider =
StateNotifierProvider<MarketBrowseNotifier, MarketBrowseState>((ref) {
  final n = MarketBrowseNotifier(ref);
  // chargement auto
  Future.microtask(() => n.load());
  return n;
});

// Provider pour lire les filtres et la vue filtrée
final marketFiltersProvider = Provider<MarketFilters>((ref) {
  final n = ref.read(marketBrowseProvider.notifier);
  return n.filters;
});

final marketFilteredOffresProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final n = ref.read(marketBrowseProvider.notifier);
  ref.watch(marketBrowseProvider); // pour rebuild
  return n.filtered;
});

final marketCompareRowsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final n = ref.read(marketBrowseProvider.notifier);
  ref.watch(marketBrowseProvider);
  return n.compareRows;
});
