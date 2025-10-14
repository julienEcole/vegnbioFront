import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/commande.model.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../services/restaurant_service.dart';
import '../../services/auth/real_auth_service.dart';

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
    // Attendre que l'authentification soit initialisée avant de charger les commandes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommandes();
    });
  }

  Future<void> _loadCommandes() async {
    try {
      // print('🔄 [OrdersScreen] Début du chargement des commandes...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Attendre que l'authentification soit initialisée
      await ref.read(authProvider.notifier).checkAuthStatus();
      
      final authState = ref.read(authProvider);
      // print('🔐 [OrdersScreen] État d\'authentification: ${authState.isAuthenticated}');
      
      // Vérifier si l'utilisateur est connecté
      if (!authState.isAuthenticated || authState.userData == null) {
        // print('❌ [OrdersScreen] Utilisateur non connecté');
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      // Récupérer le token depuis le service d'authentification
      final authService = RealAuthService();
      final token = authService.token;
      final userId = authState.userData!['id'] as int;
      
      // print('👤 [OrdersScreen] User ID: $userId');
      // print('🔑 [OrdersScreen] Token: ${token != null ? 'Présent' : 'Absent'}');

      // Charger les commandes et restaurants en parallèle
      // print('📡 [OrdersScreen] Appel API getUserCommandes...');
      final results = await Future.wait([
        ApiService().getUserCommandes(
          userId: userId,
          token: token,
        ),
        RestaurantService.getRestaurantsMap(),
      ]);

      final commandes = results[0] as List<Commande>;
      final restaurants = results[1] as Map<int, Restaurant>;
      
      // print('✅ [OrdersScreen] ${commandes.length} commandes récupérées');
      
      setState(() {
        _commandes = commandes;
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      // print('❌ [OrdersScreen] Erreur lors du chargement: $e');
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
          
          // Informations de livraison
          if (commande.deliveryInfo != null && commande.deliveryInfo!.estimatedTime != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'À récupérer le ${_formatDateTime(commande.deliveryInfo!.estimatedTime!)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
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

  Widget _buildCommandeItem(dynamic item) {
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'draft':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'paid':
      case 'confirmed':
      case 'preparing':
      case 'ready':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'payment_failed':
        return Colors.red.shade700;
      case 'suspicious':
        return Colors.orange.shade900;
      case 'to_pay_restaurant':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'draft':
        return Icons.edit_outlined;
      case 'pending':
        return Icons.access_time;
      case 'paid':
        return Icons.check_circle_outline;
      case 'confirmed':
        return Icons.verified_outlined;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'ready':
        return Icons.done_all;
      case 'delivered':
        return Icons.delivery_dining;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'refunded':
        return Icons.undo_outlined;
      case 'payment_failed':
        return Icons.error_outline;
      case 'suspicious':
        return Icons.warning_outlined;
      case 'to_pay_restaurant':
        return Icons.store;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'draft':
        return 'Brouillon';
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payée';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      case 'refunded':
        return 'Remboursée';
      case 'payment_failed':
        return 'Paiement échoué';
      case 'suspicious':
        return 'Suspecte';
      case 'to_pay_restaurant':
        return 'À payer au restaurant';
      default:
        return statut;
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

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
