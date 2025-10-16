import 'menu.dart';

class CartItem {
  final Menu menu;
  final int quantite;
  final int restaurantId;

  CartItem({
    required this.menu,
    required this.quantite,
    required this.restaurantId,
  });

  double get totalPrice => menu.prix * quantite;

  CartItem copyWith({
    Menu? menu,
    int? quantite,
    int? restaurantId,
  }) {
    return CartItem(
      menu: menu ?? this.menu,
      quantite: quantite ?? this.quantite,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }

  Map<String, dynamic> toCommandeItemJson() {
    return {
      'menuId': menu.id,
      'nom': menu.titre,
      'prixUnitaire': menu.prix,
      'quantite': quantite,
    };
  }

  // Sérialisation pour le stockage local
  Map<String, dynamic> toJson() {
    return {
      'menu': menu.toJson(),
      'quantite': quantite,
      'restaurantId': restaurantId,
    };
  }

  // Désérialisation depuis le stockage local
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menu: Menu.fromJson(json['menu']),
      quantite: json['quantite'] as int,
      restaurantId: json['restaurantId'] as int,
    );
  }

  @override
  String toString() {
    return 'CartItem(menu: ${menu.titre}, quantite: $quantite, restaurantId: $restaurantId, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.menu.id == menu.id &&
        other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    return menu.id.hashCode ^ restaurantId.hashCode;
  }
}
