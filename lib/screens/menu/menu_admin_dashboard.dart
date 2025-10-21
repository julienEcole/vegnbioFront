import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import 'menu_form_screen.dart';

/// Dashboard d'administration des menus pour les restaurateurs, fournisseurs et admins
/// Affiche la liste des menus et permet de les gérer
class MenuAdminDashboard extends ConsumerStatefulWidget {
  final int? restaurantId;
  const MenuAdminDashboard({super.key, this.restaurantId});

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

      // charger les restos pour l'affichage du nom + filtre
      final restaurants = await _apiService.getRestaurants();

      // SI restaurantId fourni → on ne charge QUE les menus de ce resto
      final menus = widget.restaurantId != null
          ? await _apiService.getMenusByRestaurant(widget.restaurantId!)
          : await _apiService.getMenus();

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
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // —— Shell centré + largeur max pour éviter le full width sur le web
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
      body: wrapShell(_buildBody()),
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
        // padding horizontal géré par le shell ; on garde un padding vertical doux ici
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _menus.length,
        itemBuilder: (context, index) {
          final menu = _menus[index];
          final restaurant = _getRestaurantById(menu.restaurantId);
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
                  // En-tête avec image et titre
                  Row(
                    children: [
                      // Image du menu
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: menu.imageUrl != null
                            ? Image.network(
                          menu.imageUrl!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _menuFallbackThumb(context);
                          },
                        )
                            : _menuFallbackThumb(context),
                      ),
                      const SizedBox(width: 14),

                      // Informations du menu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.titre,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Restaurant propriétaire
                            if (restaurant != null)
                              Row(
                                children: [
                                  Icon(Icons.restaurant, size: 18, color: scheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    restaurant.nom,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${restaurant.quartier}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 6),

                            // Prix et disponibilité
                            Row(
                              children: [
                                Text(
                                  '💰 ${menu.prixText}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: menu.disponible
                                        ? Colors.green.withOpacity(0.10)
                                        : Colors.red.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Menu d'actions (inchangé fonctionnellement)
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
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Modifier'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
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
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Produits et allergènes
                  if (menu.produits.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: menu.produits.map((produit) {
                        return Chip(
                          label: Text(produit),
                          backgroundColor: scheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: scheme.onSecondaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),

                  if (menu.allergenes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: menu.allergenes.map((allergene) {
                        return Chip(
                          label: Text(allergene),
                          backgroundColor: Colors.orange.withOpacity(0.10),
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          side: const BorderSide(color: Colors.orange),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Boutons d'action — à gauche, plein (filled), non full width
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _editMenu(menu),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Modifier'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showDeleteConfirmation(menu),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Supprimer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
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

  Widget _menuFallbackThumb(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.restaurant_menu,
        color: scheme.onPrimaryContainer,
        size: 32,
      ),
    );
  }

  void _showCreateMenuDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuFormScreen(defaultRestaurantId: widget.restaurantId),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu "${menu.titre}" supprimé avec succès')),
      );
      _loadMenus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}
