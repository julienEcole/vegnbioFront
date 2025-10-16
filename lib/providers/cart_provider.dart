import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/menu.dart';

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantite);
  
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  bool get isEmpty => items.isEmpty;
  
  bool get isNotEmpty => items.isNotEmpty;

  // Grouper les items par restaurant
  Map<int, List<CartItem>> get itemsByRestaurant {
    final Map<int, List<CartItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.restaurantId)) {
        grouped[item.restaurantId] = [];
      }
      grouped[item.restaurantId]!.add(item);
    }
    return grouped;
  }

  // Vérifier si tous les items sont du même restaurant
  bool get isSingleRestaurant {
    if (items.isEmpty) return true;
    final firstRestaurantId = items.first.restaurantId;
    return items.every((item) => item.restaurantId == firstRestaurantId);
  }

  // Obtenir l'ID du restaurant (si tous les items sont du même restaurant)
  int? get singleRestaurantId {
    if (!isSingleRestaurant) return null;
    return items.isNotEmpty ? items.first.restaurantId : null;
  }

  // Obtenir le nombre de restaurants différents dans le panier
  int get restaurantCount => itemsByRestaurant.keys.length;

  // Obtenir la liste des restaurants dans le panier
  List<int> get restaurantIds => itemsByRestaurant.keys.toList();

  // Vérifier si on peut ajouter un item d'un restaurant différent
  bool canAddItemFromRestaurant(int restaurantId) {
    if (isEmpty) return true;
    return isSingleRestaurant && singleRestaurantId == restaurantId;
  }

  // Obtenir le message d'erreur si on ne peut pas ajouter un item
  String? getAddItemErrorMessage(int restaurantId) {
    if (canAddItemFromRestaurant(restaurantId)) return null;
    
    if (isEmpty) return null;
    
    return 'Impossible d\'ajouter des menus de restaurants différents dans la même commande. '
           'Videz votre panier ou finalisez votre commande actuelle.';
  }
}

class CartNotifier extends StateNotifier<CartState> {
  static const String _cartKey = 'vegnbio_cart';
  
  CartNotifier() : super(CartState()) {
    _loadCart();
  }

  // Charger le panier depuis le stockage local
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        final List<dynamic> itemsJson = json.decode(cartJson);
        final items = itemsJson.map((json) => CartItem.fromJson(json)).toList();
        state = state.copyWith(items: items);
        // print('🛒 [CartNotifier] Panier chargé: ${items.length} items');
      }
    } catch (e) {
      // print('❌ [CartNotifier] Erreur lors du chargement du panier: $e');
    }
  }

  // Sauvegarder le panier dans le stockage local
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = state.items.map((item) => item.toJson()).toList();
      final cartJson = json.encode(itemsJson);
      await prefs.setString(_cartKey, cartJson);
      // print('🛒 [CartNotifier] Panier sauvegardé: ${state.items.length} items');
    } catch (e) {
      // print('❌ [CartNotifier] Erreur lors de la sauvegarde du panier: $e');
    }
  }

  void addItem(Menu menu, int restaurantId, {int quantite = 1}) {
    // Vérifier si on peut ajouter cet item
    if (!state.canAddItemFromRestaurant(restaurantId)) {
      final errorMessage = state.getAddItemErrorMessage(restaurantId);
      state = state.copyWith(error: errorMessage);
      // print('❌ [CartNotifier] Impossible d\'ajouter l\'item: $errorMessage');
      return;
    }

    // Effacer toute erreur précédente
    state = state.copyWith(error: null);

    final existingItemIndex = state.items.indexWhere(
      (item) => item.menu.id == menu.id && item.restaurantId == restaurantId,
    );

    if (existingItemIndex != -1) {
      // Item existe déjà, augmenter la quantité
      final existingItem = state.items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantite: existingItem.quantite + quantite,
      );
      
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingItemIndex] = updatedItem;
      
      state = state.copyWith(items: updatedItems);
    } else {
      // Nouvel item
      final newItem = CartItem(
        menu: menu,
        quantite: quantite,
        restaurantId: restaurantId,
      );
      
      state = state.copyWith(items: [...state.items, newItem]);
    }
    
    _saveCart();
    // print('🛒 [CartNotifier] Item ajouté: ${menu.titre} (quantité: $quantite)');
  }

  void removeItem(Menu menu, int restaurantId) {
    final updatedItems = state.items.where(
      (item) => !(item.menu.id == menu.id && item.restaurantId == restaurantId),
    ).toList();
    
    state = state.copyWith(items: updatedItems);
    _saveCart();
    // print('🛒 [CartNotifier] Item supprimé: ${menu.titre}');
  }

  void updateItemQuantity(Menu menu, int restaurantId, int newQuantite) {
    if (newQuantite <= 0) {
      removeItem(menu, restaurantId);
      return;
    }

    final existingItemIndex = state.items.indexWhere(
      (item) => item.menu.id == menu.id && item.restaurantId == restaurantId,
    );

    if (existingItemIndex != -1) {
      final existingItem = state.items[existingItemIndex];
      final updatedItem = existingItem.copyWith(quantite: newQuantite);
      
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingItemIndex] = updatedItem;
      
      state = state.copyWith(items: updatedItems);
      _saveCart();
      // print('🛒 [CartNotifier] Quantité mise à jour: ${menu.titre} -> $newQuantite');
    }
  }

  void clearCart() {
    state = CartState();
    _saveCart();
    // print('🛒 [CartNotifier] Panier vidé');
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  // Obtenir la quantité d'un item spécifique
  int getItemQuantity(Menu menu, int restaurantId) {
    final item = state.items.firstWhere(
      (item) => item.menu.id == menu.id && item.restaurantId == restaurantId,
      orElse: () => CartItem(menu: menu, quantite: 0, restaurantId: restaurantId),
    );
    return item.quantite;
  }

  // Vérifier si un item est dans le panier
  bool hasItem(Menu menu, int restaurantId) {
    return state.items.any(
      (item) => item.menu.id == menu.id && item.restaurantId == restaurantId,
    );
  }
}

// Provider pour l'état du panier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// Provider pour le nombre total d'items dans le panier
final cartItemCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.totalItems;
});

// Provider pour le prix total du panier
final cartTotalPriceProvider = Provider<double>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.totalPrice;
});

// Provider pour vérifier si le panier est vide
final cartIsEmptyProvider = Provider<bool>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.isEmpty;
});
