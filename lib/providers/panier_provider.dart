import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/panier_item.dart';
import '../models/menu.dart';

class PanierNotifier extends StateNotifier<List<PanierItem>> {
  PanierNotifier() : super([]);

  // Ajouter un item au panier
  void ajouterItem(Menu menu, {int quantite = 1}) {
    final existingItemIndex = state.indexWhere(
      (item) => item.menuId == menu.id,
    );

    if (existingItemIndex != -1) {
      // L'item existe déjà, augmenter la quantité
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWithQuantite(
        existingItem.quantite + quantite,
      );
      state = [
        ...state.sublist(0, existingItemIndex),
        updatedItem,
        ...state.sublist(existingItemIndex + 1),
      ];
    } else {
      // Nouvel item
      final newItem = PanierItem.fromMenu(menu, quantite: quantite);
      state = [...state, newItem];
    }
  }

  // Supprimer un item du panier
  void supprimerItem(int menuId) {
    state = state.where((item) => item.menuId != menuId).toList();
  }

  // Modifier la quantité d'un item
  void modifierQuantite(int menuId, int nouvelleQuantite) {
    if (nouvelleQuantite <= 0) {
      supprimerItem(menuId);
      return;
    }

    final itemIndex = state.indexWhere((item) => item.menuId == menuId);
    if (itemIndex != -1) {
      final updatedItem = state[itemIndex].copyWithQuantite(nouvelleQuantite);
      state = [
        ...state.sublist(0, itemIndex),
        updatedItem,
        ...state.sublist(itemIndex + 1),
      ];
    }
  }

  // Vider le panier
  void viderPanier() {
    state = [];
  }

  // Calculer le total du panier
  double get totalPanier {
    return state.fold(0.0, (sum, item) => sum + item.totalLigne);
  }

  // Calculer le nombre total d'articles
  int get nombreTotalArticles {
    return state.fold(0, (sum, item) => sum + item.quantite);
  }

  // Vérifier si le panier est vide
  bool get estVide => state.isEmpty;

  // Vérifier si un menu est dans le panier
  bool contientMenu(int menuId) {
    return state.any((item) => item.menuId == menuId);
  }

  // Obtenir la quantité d'un menu dans le panier
  int getQuantiteMenu(int menuId) {
    final item = state.firstWhere(
      (item) => item.menuId == menuId,
      orElse: () => PanierItem(
        menuId: menuId,
        nom: '',
        prix: 0,
        quantite: 0,
      ),
    );
    return item.quantite;
  }

  // Obtenir le total HT (sans TVA)
  double get totalHT {
    // Supposons un taux de TVA de 10%
    const double tauxTVA = 0.10;
    return totalPanier / (1 + tauxTVA);
  }

  // Obtenir le montant de la TVA
  double get montantTVA {
    return totalPanier - totalHT;
  }

  // Obtenir le taux de TVA
  double get tauxTVA => 10.0; // 10%

  // Convertir le panier en liste de CommandeItem pour l'API
  List<Map<String, dynamic>> toCommandeItemsJson() {
    return state.map((item) => item.toCommandeItemJson()).toList();
  }
}

// Provider pour le panier
final panierProvider = StateNotifierProvider<PanierNotifier, List<PanierItem>>((ref) {
  return PanierNotifier();
});

// Provider pour les statistiques du panier
final panierStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final panier = ref.watch(panierProvider);
  final notifier = ref.read(panierProvider.notifier);
  
  return {
    'nombreArticles': notifier.nombreTotalArticles,
    'nombreItems': panier.length,
    'totalHT': notifier.totalHT,
    'montantTVA': notifier.montantTVA,
    'totalTTC': notifier.totalPanier,
    'tauxTVA': notifier.tauxTVA,
    'estVide': notifier.estVide,
  };
});

// Provider pour vérifier si un menu est dans le panier
final menuDansPanierProvider = Provider.family<bool, int>((ref, menuId) {
  final panier = ref.watch(panierProvider);
  return panier.any((item) => item.menuId == menuId);
});

// Provider pour obtenir la quantité d'un menu dans le panier
final quantiteMenuProvider = Provider.family<int, int>((ref, menuId) {
  final panier = ref.watch(panierProvider);
  final item = panier.firstWhere(
    (item) => item.menuId == menuId,
    orElse: () => PanierItem(
      menuId: menuId,
      nom: '',
      prix: 0,
      quantite: 0,
    ),
  );
  return item.quantite;
});
