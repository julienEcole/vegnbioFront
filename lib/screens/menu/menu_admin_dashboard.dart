import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import 'menu_form_screen.dart';

/// Dashboard d'administration des menus pour les restaurateurs, fournisseurs et admins
/// Affiche la liste des menus et permet de les gérer
class MenuAdminDashboard extends ConsumerStatefulWidget {
  const MenuAdminDashboard({super.key});

  @override
  ConsumerState<MenuAdminDashboard> createState() => _MenuAdminDashboardState();
}

class _MenuAdminDashboardState extends ConsumerState<MenuAdminDashboard> {
  final ApiService _apiService = ApiService();
  List<Menu> _menus = [];
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final menus = await _apiService.getMenus();
      final restaurants = await _apiService.getRestaurants();
      
      setState(() {
        _menus = menus;
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

  Restaurant? _getRestaurantById(int restaurantId) {
    try {
      return _restaurants.firstWhere((r) => r.id == restaurantId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍽️ Administration des Menus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateMenuDialog,
            tooltip: 'Créer un nouveau menu',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenus,
            tooltip: 'Actualiser la liste',
          ),
        ],
      ),
      body: _buildBody(),
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
            Text('Chargement des menus...'),
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
              onPressed: _loadMenus,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun menu trouvé',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Commencez par créer votre premier menu',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateMenuDialog,
              icon: const Icon(Icons.add),
              label: const Text('Créer un menu'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMenus,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _menus.length,
        itemBuilder: (context, index) {
          final menu = _menus[index];
          final restaurant = _getRestaurantById(menu.restaurantId);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec image et titre
                  Row(
                    children: [
                      // Image du menu
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: menu.imageUrl != null
                            ? Image.network(
                                menu.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      size: 32,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  size: 32,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Informations du menu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.titre,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Restaurant propriétaire
                            if (restaurant != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    restaurant.nom,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${restaurant.quartier}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            
                            const SizedBox(height: 4),
                            
                            // Prix et disponibilité
                            Row(
                              children: [
                                Text(
                                  '💰 ${menu.prixText}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: menu.disponible 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: menu.disponible ? Colors.green : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    menu.disponible ? '✅ Disponible' : '❌ Indisponible',
                                    style: TextStyle(
                                      color: menu.disponible ? Colors.green : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Menu d'actions
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editMenu(menu);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(menu);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Modifier'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  if (menu.description != null && menu.description!.isNotEmpty)
                    Text(
                      '📝 ${menu.description}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Date
                  Text(
                    '📅 ${menu.formattedDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Produits et allergènes
                  if (menu.produits.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: menu.produits.map((produit) {
                        return Chip(
                          label: Text(produit),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  
                  if (menu.allergenes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: menu.allergenes.map((allergene) {
                        return Chip(
                          label: Text(allergene),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          side: const BorderSide(color: Colors.orange),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editMenu(menu),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(menu),
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateMenuDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MenuFormScreen(),
      ),
    ).then((_) => _loadMenus());
  }

  void _editMenu(Menu menu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuFormScreen(menuToEdit: menu),
      ),
    ).then((_) => _loadMenus());
  }

  void _showDeleteConfirmation(Menu menu) {
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenu(Menu menu) async {
    try {
      await _apiService.deleteMenu(menu.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu "${menu.titre}" supprimé avec succès')),
      );
      _loadMenus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}
