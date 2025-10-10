import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_provider.dart';

class CartFloatingButton extends ConsumerWidget {
  const CartFloatingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    final int itemCount = cart.items.fold(0, (sum, it) => sum + (it.quantite ?? 0));
    final double total = cart.items.fold(0.0, (sum, it) {
      final q = (it.quantite ?? 0);
      final p = it.menu.prix; // suppose que menu.prix est double
      return sum + (p * q);
    });

    if (itemCount <= 0) {
      // Rien dans le panier → pas de FAB
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => context.go('/panier'), // adapte la route si besoin
      icon: const Icon(Icons.shopping_cart_checkout),
      label: Text('$itemCount • ${total.toStringAsFixed(2)} €'),
    );
  }
}
