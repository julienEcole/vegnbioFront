import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_item.dart';
import '../../services/api_service.dart';
import '../../services/auth/real_auth_service.dart';
import '../../services/commande.service.dart';
import '../../widgets/delivery_time_selector.dart';
import '../../widgets/payment/unified_payment_modal.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isProcessingPayment = false;
  DateTime? _selectedDeliveryTime;

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);

    // Non connecté
    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: _appBar(context),
        body: _centeredShell(
          child: _EmptyState(
            icon: Icons.lock_outline,
            title: 'Connexion requise',
            subtitle: 'Vous devez être connecté pour passer commande',
            actionText: 'Se connecter',
            onAction: () => context.go('/profil?view=login'),
          ),
        ),
      );
    }

    // Panier vide
    if (cartState.isEmpty) {
      return Scaffold(
        appBar: _appBar(context),
        body: _centeredShell(
          child: _EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Votre panier est vide',
            subtitle: 'Ajoutez des menus à votre panier pour commencer',
            actionText: 'Voir les menus',
            onAction: () => context.go('/menus'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _appBar(context),
      body: SingleChildScrollView(
        child: _centeredShell(
          child: Column(
            children: [
              // Bandeau d’erreur
              if (cartState.error != null) _ErrorBanner(
                message: cartState.error!,
                onClose: () => ref.read(cartProvider.notifier).setError(null),
              ),

              // Sélecteur d’horaire
              _SectionCard(
                title: 'Choix de l’horaire',
                accentColor: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DeliveryTimeSelector(
                    selectedTime: _selectedDeliveryTime,
                    onTimeSelected: (time) => setState(() => _selectedDeliveryTime = time),
                    minMinutesFromNow: 15,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Commandes par restaurant
              _buildRestaurantOrders(cartState),

              const SizedBox(height: 12),

              // Résumé global : liste des items + TTC gauche / Total global droite
              _buildCartSummary(cartState),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      title: const Text('Panier'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => _showClearCartDialog(context),
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Vider le panier',
        ),
      ],
    );
  }

  /// Conteneur centré avec largeur max sur web + padding latéral
  Widget _centeredShell({required Widget child}) {
    final maxWidth = kIsWeb ? 1100.0 : double.infinity;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 16 : 8,
            vertical: 12,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Liste des commandes groupées par restaurant (UI relookée)
  Widget _buildRestaurantOrders(CartState cartState) {
    final itemsByRestaurant = cartState.itemsByRestaurant;
    if (itemsByRestaurant.isEmpty) {
      return _SectionCard(
        title: 'Votre panier',
        accentColor: Colors.grey,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('Aucun article'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: itemsByRestaurant.entries.map((entry) {
        final restaurantId = entry.key;
        final items = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _RestaurantOrderCard(
            restaurantId: restaurantId,
            items: items,
            onOrderPressed: () {
              if (_selectedDeliveryTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez sélectionner un horaire de réception valide'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              _processRestaurantOrder(restaurantId, items);
            },
            removeItem: (item) => ref.read(cartProvider.notifier).removeItem(item.menu, item.restaurantId),
            updateQty: (item, q) => ref.read(cartProvider.notifier).updateItemQuantity(item.menu, item.restaurantId, q),
          ),
        );
      }).toList(),
    );
  }

  /// Résumé global + liste compacte des articles (avec corbeille)
  Widget _buildCartSummary(CartState cartState) {
    final totalHT = cartState.totalPrice;
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    return _SectionCard(
      title: 'Résumé de votre panier',
      accentColor: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cartState.restaurantCount > 1)
            _InfoBanner(
              text:
              '${cartState.restaurantCount} restaurants différents. Chaque restaurant sera commandé séparément.',
            ),

          // Liste compacte des articles (titre • qty • prix) + corbeille
          const SizedBox(height: 8),
          ...cartState.items.map((item) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.menu.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('x${item.quantite}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  Text('${item.totalPrice.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => ref.read(cartProvider.notifier).removeItem(item.menu, item.restaurantId),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Retirer',
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 12),
          const Divider(),

          // LIGNE SPECIFIQUE DEMANDÉE : TTC à gauche / Total global à droite
          Row(
            children: [
              // Total TTC (gauche)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total TTC',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${totalTTC.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Total global (droite) : détail HT + TVA + Global
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total global',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('HT: ${totalHT.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('TVA (20%): ${totalTVA.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      'TTC: ${totalTTC.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Commander tous les restaurants (on garde la même méthode)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessingPayment
                  ? null
                  : () {
                if (_selectedDeliveryTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner un horaire de réception valide'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                _processAllOrders(cartState);
              },
              icon: _isProcessingPayment
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
                  : const Icon(Icons.shopping_bag_outlined),
              label: Text(
                _isProcessingPayment
                    ? 'Traitement…'
                    : 'Commander tous les restaurants (${cartState.restaurantCount})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider votre panier ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
            },
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  // ----- Les méthodes de paiement/commande EXISTANTES (inchangées) -----
  void _processRestaurantOrder(int restaurantId, List<CartItem> items) async {
    final totalHT = items.fold(0.0, (sum, item) => sum + (item.menu.prix * item.quantite));
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    if (_selectedDeliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un horaire de livraison'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (totalTTC <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide'), backgroundColor: Colors.red),
      );
      return;
    }

    // ✅ OUVERTURE DE LA MODALE STRIPE
    final paymentResult = await UnifiedPaymentModal.showPaymentModal(
      context: context,
      amount: totalTTC,
      currency: 'eur',
      description: 'Commande restaurant $restaurantId (${items.length} article${items.length > 1 ? 's' : ''})',
    );
    if (paymentResult == null) return;         // fermé par l’utilisateur
    if (!paymentResult.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement échoué: ${paymentResult.error}'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isProcessingPayment = true);
    try {
      final authService = RealAuthService();
      final token = authService.token;

      final commande = await ApiService().createCommande(
        restaurantId: restaurantId,
        items: items,
        tvaRate: 20.0,
        currency: 'EUR',
        token: token,
      );

      final paymentResult2 = await CommandeService.completePayment(
        commandeId: commande.id,
        paymentIntentId: paymentResult.paymentIntentId ?? '',
        paymentMethodId: paymentResult.paymentMethodId ?? '',
        amount: totalTTC,
        currency: 'EUR',
        cardBrand: paymentResult.cardBrand,
        cardLast4: paymentResult.cardLast4,
        deliveryInfo: {
          'type': 'pickup',
          'estimatedTime': _selectedDeliveryTime?.toIso8601String(),
        },
        token: token,
      );

      if (!paymentResult2['success']) {
        throw Exception(paymentResult2['error']);
      }

      // vider les items de ce resto
      for (final it in List<CartItem>.from(items)) {
        ref.read(cartProvider.notifier).removeItem(it.menu, it.restaurantId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Commande payée et créée ! ID: ${commande.id}'), backgroundColor: Colors.green),
        );
        // Rediriger vers la page des commandes
        context.go('/commandes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }


  void _processAllOrders(CartState cartState) async {
    final totalHT = cartState.items.fold(0.0, (s, it) => s + (it.menu.prix * it.quantite));
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    if (_selectedDeliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un horaire de livraison'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (totalTTC <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant global invalide'), backgroundColor: Colors.red),
      );
      return;
    }

    // ✅ OUVERTURE DE LA MODALE STRIPE
    final paymentResult = await UnifiedPaymentModal.showPaymentModal(
      context: context,
      amount: totalTTC,
      currency: 'eur',
      description:
      'Commande globale (${cartState.restaurantCount} restaurant${cartState.restaurantCount > 1 ? 's' : ''}, ${cartState.items.length} article${cartState.items.length > 1 ? 's' : ''})',
    );
    if (paymentResult == null) return;
    if (!paymentResult.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement échoué: ${paymentResult.error}'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isProcessingPayment = true);
    try {
      final authService = RealAuthService();
      final token = authService.token;

      final itemsByRestaurant = cartState.itemsByRestaurant;
      final List<CartItem> itemsToRemove = [];

      for (final entry in itemsByRestaurant.entries) {
        final restaurantId = entry.key;
        final items = entry.value;

        final commande = await ApiService().createCommande(
          restaurantId: restaurantId,
          items: items,
          tvaRate: 20.0,
          currency: 'EUR',
          token: token,
        );

        final rTotalHT = items.fold(0.0, (s, it) => s + (it.menu.prix * it.quantite));
        final rTotalTTC = rTotalHT * 1.2;

        final paymentResult2 = await CommandeService.completePayment(
          commandeId: commande.id,
          paymentIntentId: paymentResult.paymentIntentId ?? '',
          paymentMethodId: paymentResult.paymentMethodId ?? '',
          amount: rTotalTTC,
          currency: 'EUR',
          cardBrand: paymentResult.cardBrand,
          cardLast4: paymentResult.cardLast4,
          deliveryInfo: {
            'type': 'pickup',
            'estimatedTime': _selectedDeliveryTime?.toIso8601String(),
          },
          token: token,
        );
        if (!paymentResult2['success']) throw Exception(paymentResult2['error']);

        itemsToRemove.addAll(items);
      }

      for (final it in itemsToRemove) {
        ref.read(cartProvider.notifier).removeItem(it.menu, it.restaurantId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commandes payées et créées !'), backgroundColor: Colors.green),
        );
        // Rediriger vers la page des commandes
        context.go('/commandes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }


}

// =================== UI SUBWIDGETS (style only) ===================

class _SectionCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  const _SectionCard({required this.title, required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.25), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header coloré
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 18, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    )),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(onPressed: onClose, icon: Icon(Icons.close, color: Colors.red.shade700)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 12, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onAction, child: Text(actionText)),
        ],
      ),
    );
  }
}

class _RestaurantOrderCard extends StatelessWidget {
  final int restaurantId;
  final List<CartItem> items;
  final VoidCallback onOrderPressed;
  final void Function(CartItem) removeItem;
  final void Function(CartItem, int) updateQty;

  const _RestaurantOrderCard({
    required this.restaurantId,
    required this.items,
    required this.onOrderPressed,
    required this.removeItem,
    required this.updateQty,
  });

  @override
  Widget build(BuildContext context) {
    final totalHT = items.fold(0.0, (sum, it) => sum + it.totalPrice);
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    final accent = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accent.withOpacity(0.25), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Restaurant ID: $restaurantId',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      )),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    '${items.length} article${items.length > 1 ? 's' : ''}',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                )
              ],
            ),
          ),

          // items
          ...items.map((it) => _RestaurantItemTile(
            item: it,
            removeItem: () => removeItem(it),
            updateQty: (q) => updateQty(it, q),
          )),

          // footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Column(
              children: [
                _priceRow(context, 'Sous-total HT', totalHT),
                const SizedBox(height: 4),
                _priceRow(context, 'TVA (20%)', totalTVA),
                const Divider(height: 16),
                _priceRow(context, 'Total TTC', totalTTC, bold: true, highlight: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOrderPressed,
                    icon: const Icon(Icons.shopping_basket_outlined),
                    label: const Text('Commander ce restaurant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, double value, {bool bold = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          '${value.toStringAsFixed(2)} €',
          style: (highlight
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _RestaurantItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback removeItem;
  final void Function(int) updateQty;

  const _RestaurantItemTile({
    required this.item,
    required this.removeItem,
    required this.updateQty,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.menu.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: removeItem,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                tooltip: 'Retirer du panier',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${item.menu.prix.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              // Contrôles quantité
              IconButton(
                onPressed: () => updateQty(item.quantite - 1),
                icon: const Icon(Icons.remove, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${item.quantite}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => updateQty(item.quantite + 1),
                icon: const Icon(Icons.add, size: 18),
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Total :', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${item.totalPrice.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
