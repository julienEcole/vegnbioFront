import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_item.dart';
import '../../services/api_service.dart';
import '../../models/commande.dart';
import '../../widgets/delivery_time_selector.dart';
import '../../widgets/payment/payment_modal.dart';

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

    // Vérifier si l'utilisateur est connecté
    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Panier'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Connexion requise',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Vous devez être connecté pour passer commande',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/profil?view=login');
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    // Vérifier si le panier est vide
    if (cartState.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Panier'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Votre panier est vide',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez des menus à votre panier pour commencer',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/menus');
                },
                child: const Text('Voir les menus'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _showClearCartDialog(context);
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Vider le panier',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Message d'erreur si présent
            if (cartState.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cartState.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        print('🔴 [CartPage] Tentative de fermeture du popup d\'erreur');
                        ref.read(cartProvider.notifier).setError(null);
                        print('🔴 [CartPage] Popup d\'erreur fermé');
                      },
                      icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            
            // Sélecteur d'horaire de réception
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DeliveryTimeSelector(
                selectedTime: _selectedDeliveryTime,
                onTimeSelected: (time) {
                  setState(() {
                    _selectedDeliveryTime = time;
                  });
                },
                minMinutesFromNow: 15,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Liste des commandes par restaurant
            _buildRestaurantOrders(cartState),
            
            // Résumé et boutons de paiement
            _buildCartSummary(cartState),
          ],
        ),
      ),
    );
  }

  /// Construire la liste des commandes groupées par restaurant
  Widget _buildRestaurantOrders(CartState cartState) {
    final itemsByRestaurant = cartState.itemsByRestaurant;
    
    if (itemsByRestaurant.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Votre panier est vide',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: itemsByRestaurant.entries.map((entry) {
        final restaurantId = entry.key;
        final items = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: _buildRestaurantOrderCard(restaurantId, items),
        );
      }).toList(),
    );
  }

  /// Construire une carte de commande pour un restaurant
  Widget _buildRestaurantOrderCard(int restaurantId, List<CartItem> items) {
    final totalHT = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du restaurant
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
          Expanded(
                  child: Text(
                    'Restaurant ID: $restaurantId',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '${items.length} article${items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des items du restaurant
          ...items.map((item) => _buildCartItemCard(item)).toList(),
          
          // Résumé de la commande du restaurant
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sous-total HT:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${totalHT.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA (20%):',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${totalTVA.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total TTC:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalTTC.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Commander ce restaurant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du menu et restaurant
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          item.menu.titre,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Restaurant ID: ${item.restaurantId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(
                      item.menu,
                      item.restaurantId,
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Prix unitaire et quantité
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.menu.prix.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Contrôles de quantité
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).updateItemQuantity(
                          item.menu,
                          item.restaurantId,
                          item.quantite - 1,
                        );
                      },
                      icon: const Icon(Icons.remove, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.quantite.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).updateItemQuantity(
                          item.menu,
                          item.restaurantId,
                          item.quantite + 1,
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Total de la ligne
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${item.totalPrice.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartState cartState) {
    final totalHT = cartState.totalPrice;
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Résumé global
          if (cartState.restaurantCount > 1) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${cartState.restaurantCount} restaurants différents dans votre panier. '
                      'Chaque restaurant sera commandé séparément.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Résumé des prix globaux
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total global HT:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${totalHT.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TVA globale (20%):',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${totalTVA.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total global TTC:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${totalTTC.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bouton pour commander tous les restaurants
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : () {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Commander tous les restaurants (${cartState.restaurantCount})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
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

  /// Traiter la commande d'un restaurant spécifique
  void _processRestaurantOrder(int restaurantId, List<CartItem> items) async {
    // Calculer le total pour le paiement
    final totalHT = items.fold(0.0, (sum, item) => sum + (item.menu.prix * item.quantite));
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    // Vérifier l'horaire de livraison
    if (_selectedDeliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un horaire de livraison'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ouvrir le modal de paiement
    final paymentResult = await PaymentModal.showPaymentModal(
      context: context,
      amount: totalTTC,
      currency: 'EUR',
      description: 'Commande restaurant $restaurantId (${items.length} article${items.length > 1 ? 's' : ''})',
    );

    if (paymentResult == null) {
      // L'utilisateur a annulé le paiement
      return;
    }

    if (!paymentResult.isSuccess) {
      // Le paiement a échoué
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement échoué: ${paymentResult.errorMessage}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Le paiement a réussi, procéder à la commande
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      print('💳 [CartPage] Paiement réussi: ${paymentResult.paymentIntentId}');
      print('🛒 [CartPage] Traitement de la commande pour le restaurant $restaurantId');
      print('🕐 [CartPage] Horaire de réception sélectionné: $_selectedDeliveryTime');
      
      // Créer la commande via l'API
      final commande = await ApiService().createCommande(
        restaurantId: restaurantId,
        items: items,
        tvaRate: 20.0,
        currency: 'EUR',
      );

      print('✅ [CartPage] Commande créée avec succès: ID ${commande.id}');
      
      // Supprimer les items de ce restaurant du panier
      final itemsToRemove = List<CartItem>.from(items);
      for (final item in itemsToRemove) {
        ref.read(cartProvider.notifier).removeItem(item.menu, item.restaurantId);
      }
      
      print('🗑️ [CartPage] ${itemsToRemove.length} items supprimés du panier pour le restaurant $restaurantId');
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande payée et créée avec succès ! ID: ${commande.id}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      print('❌ [CartPage] Erreur lors de la création de la commande: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la commande: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
      setState(() {
        _isProcessingPayment = false;
      });
      }
    }
  }

  /// Traiter toutes les commandes (tous les restaurants)
  void _processAllOrders(CartState cartState) async {
    // Calculer le total global pour le paiement
    final totalHT = cartState.items.fold(0.0, (sum, item) => sum + (item.menu.prix * item.quantite));
    final totalTVA = totalHT * 0.2;
    final totalTTC = totalHT + totalTVA;

    // Vérifier l'horaire de livraison
    if (_selectedDeliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un horaire de livraison'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ouvrir le modal de paiement
    final paymentResult = await PaymentModal.showPaymentModal(
      context: context,
      amount: totalTTC,
      currency: 'EUR',
      description: 'Commande globale (${cartState.restaurantCount} restaurant${cartState.restaurantCount > 1 ? 's' : ''}, ${cartState.items.length} article${cartState.items.length > 1 ? 's' : ''})',
    );

    if (paymentResult == null) {
      // L'utilisateur a annulé le paiement
      return;
    }

    if (!paymentResult.isSuccess) {
      // Le paiement a échoué
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement échoué: ${paymentResult.errorMessage}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Le paiement a réussi, procéder aux commandes
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      print('💳 [CartPage] Paiement global réussi: ${paymentResult.paymentIntentId}');
      print('🛒 [CartPage] Traitement de toutes les commandes (${cartState.restaurantCount} restaurants)');
      print('🕐 [CartPage] Horaire de réception sélectionné: $_selectedDeliveryTime');
      
      final itemsByRestaurant = cartState.itemsByRestaurant;
      final List<Commande> commandesCreees = [];
      final List<CartItem> itemsToRemove = [];
      
      // Traiter chaque restaurant séparément
      for (final entry in itemsByRestaurant.entries) {
        final restaurantId = entry.key;
        final items = entry.value;
        
        print('🛒 [CartPage] Traitement du restaurant $restaurantId (${items.length} items)');
        
        // Créer la commande pour ce restaurant
        final commande = await ApiService().createCommande(
          restaurantId: restaurantId,
          items: items,
          tvaRate: 20.0,
          currency: 'EUR',
        );

        commandesCreees.add(commande);
        // Ajouter les items à la liste de suppression
        itemsToRemove.addAll(items);
        print('✅ [CartPage] Commande créée pour le restaurant $restaurantId: ID ${commande.id}');
      }
      
      // Supprimer uniquement les items des commandes réussies
      for (final item in itemsToRemove) {
        ref.read(cartProvider.notifier).removeItem(item.menu, item.restaurantId);
      }
      print('🗑️ [CartPage] ${itemsToRemove.length} items supprimés du panier après création de ${commandesCreees.length} commandes');
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${commandesCreees.length} commandes payées et créées avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      print('❌ [CartPage] Erreur lors de la création des commandes: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création des commandes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }
}
