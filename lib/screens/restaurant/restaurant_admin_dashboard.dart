import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import 'restaurant_form_screen.dart';
import '../menu/menu_admin_dashboard.dart';

/// Dashboard d'administration des restaurants pour les restaurateurs et admins
/// Affiche la liste des restaurants et permet d'accéder à la gestion des menus
class RestaurantAdminDashboard extends ConsumerStatefulWidget {
  const RestaurantAdminDashboard({super.key});

  @override
  ConsumerState<RestaurantAdminDashboard> createState() => _RestaurantAdminDashboardState();
}

class _RestaurantAdminDashboardState extends ConsumerState<RestaurantAdminDashboard> {
  final ApiService _apiService = ApiService();
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final restaurants = await _apiService.getRestaurants();
      setState(() {
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
    // —— Shell centré + largeur max pour éviter full width sur le web
    Widget wrapShell(Widget child) {
      const maxContentWidth = 1100.0;
      final width = MediaQuery.of(context).size.width;
      final hPad = width >= 1200 ? 32.0 : (width >= 900 ? 24.0 : 16.0);

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Administration des Restaurants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateRestaurantDialog,
            tooltip: 'Créer un nouveau restaurant',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRestaurants,
            tooltip: 'Actualiser la liste',
          ),
        ],
      ),
      body: wrapShell(_buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToMenuManagement,
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Gérer les Menus'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des restaurants...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRestaurants,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun restaurant trouvé',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Commencez par créer votre premier restaurant',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateRestaurantDialog,
              icon: const Icon(Icons.add),
              label: const Text('Créer un restaurant'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24), // padding vertical, l’horizontal est géré par le shell
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          final scheme = Theme.of(context).colorScheme;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec image et informations
                  Row(
                    children: [
                      // Image du restaurant
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: restaurant.primaryImageUrl != null
                            ? Image.network(
                          restaurant.primaryImageUrl!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                color: scheme.onPrimaryContainer,
                                size: 32,
                              ),
                            );
                          },
                        )
                            : Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: scheme.onPrimaryContainer,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Informations du restaurant
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.nom,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  restaurant.quartier,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            if (restaurant.adresse != null && restaurant.adresse!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                restaurant.adresse!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],

                            if (restaurant.hasImages) ...[
                              const SizedBox(height: 6),
                              Text(
                                '📸 ${restaurant.imagesCount} image${restaurant.imagesCount > 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Boutons d'action (gauche, compacts, "filled", pas full width)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _navigateToMenuManagement(restaurantId: restaurant.id),
                          icon: const Icon(Icons.restaurant_menu, size: 18),
                          label: const Text('Menus'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _editRestaurant(restaurant),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Modifier'),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateRestaurantDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RestaurantFormScreen(),
      ),
    ).then((_) => _loadRestaurants());
  }

  void _editRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantFormScreen(restaurantToEdit: restaurant),
      ),
    ).then((_) => _loadRestaurants());
  }

  void _navigateToMenuManagement({int? restaurantId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuAdminDashboard(restaurantId: restaurantId),
      ),
    );
  }
}
