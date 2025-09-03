import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/menu.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../widgets/navigation_bar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout rapide
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter',
            onSelected: (value) {
              switch (value) {
                case 'menu':
                  context.push('/admin/menu/new');
                  break;
                case 'restaurant':
                  context.push('/admin/restaurant/new');
                  break;
              }
            },
            itemBuilder: (context) => [
                              const PopupMenuItem(
                  value: 'menu',
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_menu),
                      SizedBox(width: 8),
                      Text('🍽️ Nouveau menu'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'restaurant',
                  child: Row(
                    children: [
                      Icon(Icons.restaurant),
                      SizedBox(width: 8),
                      Text('🏪 Nouveau restaurant'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Onglets en haut
          Container(
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(0, '🍽️ Menus', Icons.menu_book),
                ),
                Expanded(
                  child: _buildTabButton(1, '🏪 Restaurants', Icons.restaurant),
                ),
              ],
            ),
          ),
          // Contenu principal
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildMenusTab(),
                _buildRestaurantsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _buildMenusTab() {
    final menusAsync = ref.watch(filteredMenusProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Column(
      children: [
        // En-tête avec statistiques
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: menusAsync.when(
                  data: (menus) => Text(
                    '${menus.length} menus au total',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  loading: () => const Text('Chargement...'),
                  error: (_, __) => const Text('Erreur de chargement'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/admin/menu/new'),
                icon: const Icon(Icons.add),
                label: const Text('🍽️ Nouveau menu'),
              ),
            ],
          ),
        ),
        // Liste des menus
        Expanded(
          child: menusAsync.when(
            data: (menus) => restaurantsAsync.when(
              data: (restaurants) => _buildMenusList(menus, restaurants),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Erreur de chargement des restaurants')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur de chargement des menus')),
          ),
        ),
      ],
    );
  }

  Widget _buildMenusList(List<Menu> menus, List<Restaurant> restaurants) {
    if (menus.isEmpty) {
      return const Center(
        child: Text('Aucun menu disponible'),
      );
    }

    // Créer une map pour un accès rapide aux restaurants
    final restaurantMap = {
      for (var restaurant in restaurants) restaurant.id: restaurant
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        final restaurant = restaurantMap[menu.restaurantId];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.restaurant_menu, color: Colors.blue),
            ),
            title: Text(menu.titre),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant != null) Text('Restaurant: ${restaurant.nom}'),
                Text('Date: ${menu.formattedDate}'),
                if (menu.allergenes.isNotEmpty)
                  Text('Allergènes: ${menu.allergenes.join(', ')}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    context.push('/admin/menu/edit/${menu.id}');
                  },
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                  onPressed: () => _showDeleteMenuDialog(menu),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildRestaurantsTab() {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Column(
      children: [
        // En-tête avec statistiques
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: restaurantsAsync.when(
                  data: (restaurants) => Text(
                    '${restaurants.length} restaurants au total',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  loading: () => const Text('Chargement...'),
                  error: (_, __) => const Text('Erreur de chargement'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/admin/restaurant/new'),
                icon: const Icon(Icons.add),
                label: const Text('🏪 Nouveau restaurant'),
              ),
            ],
          ),
        ),
        // Liste des restaurants
        Expanded(
          child: restaurantsAsync.when(
            data: (restaurants) => _buildRestaurantsList(restaurants),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur de chargement')),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantsList(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Text('Aucun restaurant disponible'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.restaurant, color: Colors.green),
            ),
            title: Text(restaurant.nom),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quartier: ${restaurant.quartier}'),
                if (restaurant.adresse != null) Text('Adresse: ${restaurant.adresse}'),
                if (restaurant.equipements != null && restaurant.equipements!.isNotEmpty)
                  Text('Équipements: ${restaurant.equipements!.map((e) => e.nom).join(', ')}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    context.push('/admin/restaurant/edit/${restaurant.id}');
                  },
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                  onPressed: () => _showDeleteRestaurantDialog(restaurant),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _showDeleteMenuDialog(Menu menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le menu "${menu.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteMenu(menu);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 16),
                SizedBox(width: 4),
                Text('Supprimer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenu(Menu menu) async {
    try {
      final apiService = ApiService();
      final success = await apiService.deleteMenu(menu.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu supprimé avec succès')),
        );
        // Rafraîchir la liste immédiatement
        ref.invalidate(filteredMenusProvider);
        // Forcer le rafraîchissement
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteRestaurantDialog(Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le restaurant "${restaurant.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRestaurant(restaurant);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 16),
                SizedBox(width: 4),
                Text('Supprimer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant(Restaurant restaurant) async {
    try {
      final apiService = ApiService();
      final success = await apiService.deleteRestaurant(restaurant.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant supprimé avec succès')),
        );
        // Rafraîchir la liste immédiatement
        ref.invalidate(restaurantsProvider);
        // Forcer le rafraîchissement
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.grey[300]!,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
