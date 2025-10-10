import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';

class RestaurantMenusSheet extends ConsumerWidget {
  final int restaurantId;
  final String restaurantName;

  const RestaurantMenusSheet({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusByRestaurantProvider(restaurantId));
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    int _quantityFor(Menu menu) {
      final match = cartState.items.where(
            (it) => it.menu.id == menu.id && it.restaurantId == restaurantId,
      );
      if (match.isEmpty) return 0;
      return match.first.quantite ?? 0;
    }


    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        minChildSize: 0.35,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Menus — $restaurantName',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Corps
                Expanded(
                  child: menusAsync.when(
                    data: (menus) {
                      if (menus.isEmpty) {
                        return const Center(
                          child: Text('Aucun menu disponible pour ce restaurant.'),
                        );
                      }
                      return ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (ctx, i) {
                          final menu = menus[i];
                          final qty = _quantityFor(menu);

                          return _MenuRow(
                            menu: menu,
                            quantity: qty,
                            onAdd: () => cartNotifier.addItem(menu, restaurantId, quantite: 1),
                            onInc: () => cartNotifier.updateItemQuantity(menu, restaurantId, qty + 1),
                            onDec: () => cartNotifier.updateItemQuantity(menu, restaurantId, qty - 1),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: menus.length,
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Impossible de charger les menus.\n$e',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(menusByRestaurantProvider(restaurantId)),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final Menu menu;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _MenuRow({
    required this.menu,
    required this.quantity,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image si tu as une ImageWidget, sinon un fallback
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.fastfood),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menu.titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (menu.description != null && menu.description!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        menu.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: [
                      Chip(
                        label: Text('${menu.prix.toStringAsFixed(2)} €'),
                        backgroundColor: Colors.green.withOpacity(.1),
                      ),
                      if (menu.produits.isNotEmpty)
                        Chip(
                          label: Text('${menu.produits.length} produit(s)'),
                          backgroundColor: Colors.blueGrey.withOpacity(.08),
                        ),
                      if (menu.allergenes.isNotEmpty)
                        Chip(
                          label: Text('Allergènes: ${menu.allergenes.join(", ")}'),
                          backgroundColor: Colors.orange.withOpacity(.08),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions panier
            quantity <= 0
                ? ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Ajouter'),
            )
                : Row(
              children: [
                IconButton(onPressed: onDec, icon: const Icon(Icons.remove_circle_outline)),
                Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
                IconButton(onPressed: onInc, icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

