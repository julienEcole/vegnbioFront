import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/commande.dart';
import '../../models/commande_item.dart';
import '../../models/restaurant.dart';
import '../../models/menu.dart';
import '../../services/api_service.dart';
import '../../services/restaurant_service.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<Commande> _commandes = [];
  Map<int, Restaurant> _restaurants = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  Future<void> _loadCommandes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger les commandes et restaurants en parallèle
      final results = await Future.wait([
        ApiService().getAllCommandes(),
        RestaurantService.getRestaurantsMap(),
      ]);

      final commandes = results[0] as List<Commande>;
      final restaurants = results[1] as Map<int, Restaurant>;
      
      setState(() {
        _commandes = commandes;
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Vérifier si l'utilisateur est connecté
    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
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
                'Vous devez être connecté pour voir vos commandes',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCommandes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCommandes,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_commandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore passé de commande',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommandes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _commandes.length,
        itemBuilder: (context, index) {
          final commande = _commandes[index];
          return _buildCommandeCard(commande);
        },
      ),
    );
  }

  Widget _buildCommandeCard(Commande commande) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getStatutIcon(commande.statut),
          color: _getStatutColor(commande.statut),
        ),
        title: Text(
          'Commande #${commande.id}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getStatutColor(commande.statut),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _navigateToRestaurant(commande.restaurantId),
              child: Text(
                _getRestaurantName(commande.restaurantId),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatutColor(commande.statut),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              _formatDate(commande.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: _getStatutColor(commande.statut),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getStatutText(commande.statut),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStatutColor(commande.statut),
              ),
            ),
            Text(
              '${commande.totalTTC.toStringAsFixed(2)} €',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        children: [
          // En-tête de la commande
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatutColor(commande.statut).withOpacity(0.1),
            ),
            child: InkWell(
              onTap: () => _navigateToRestaurant(commande.restaurantId),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: _getStatutColor(commande.statut),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getRestaurantName(commande.restaurantId),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getStatutColor(commande.statut),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '${commande.items.length} article${commande.items.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatutColor(commande.statut),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Items de la commande
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Articles:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...commande.items.map((item) => _buildCommandeItem(item)).toList(),
              ],
            ),
          ),
          
          // Résumé financier
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sous-total HT:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${commande.totalHT.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA (${commande.tvaRate.toInt()}%):',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${commande.totalTVA.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total TTC:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${commande.totalTTC.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandeItem(CommandeItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _navigateToMenu(item.menuId),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.prixUnitaire.toStringAsFixed(2)} € × ${item.quantite}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${item.totalLigne.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatutColor(CommandeStatut statut) {
    switch (statut) {
      case CommandeStatut.draft:
        return Colors.grey;
      case CommandeStatut.pending:
        return Colors.orange;
      case CommandeStatut.paid:
        return Colors.green;
      case CommandeStatut.cancelled:
        return Colors.red;
      case CommandeStatut.refunded:
        return Colors.blue;
    }
  }

  IconData _getStatutIcon(CommandeStatut statut) {
    switch (statut) {
      case CommandeStatut.draft:
        return Icons.edit_outlined;
      case CommandeStatut.pending:
        return Icons.access_time;
      case CommandeStatut.paid:
        return Icons.check_circle_outline;
      case CommandeStatut.cancelled:
        return Icons.cancel_outlined;
      case CommandeStatut.refunded:
        return Icons.undo_outlined;
    }
  }

  String _getStatutText(CommandeStatut statut) {
    switch (statut) {
      case CommandeStatut.draft:
        return 'Brouillon';
      case CommandeStatut.pending:
        return 'En attente';
      case CommandeStatut.paid:
        return 'Payée';
      case CommandeStatut.cancelled:
        return 'Annulée';
      case CommandeStatut.refunded:
        return 'Remboursée';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  String _getRestaurantName(int restaurantId) {
    final restaurant = _restaurants[restaurantId];
    return restaurant?.nom ?? 'Restaurant #$restaurantId';
  }

  void _navigateToRestaurant(int restaurantId) {
    context.go('/restaurants?id=$restaurantId');
  }

  void _navigateToMenu(int? menuId) {
    if (menuId != null) {
      context.go('/menus?id=$menuId');
    }
  }
}
