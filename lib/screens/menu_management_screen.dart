import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/menu_cache_service.dart';
import '../providers/menu_provider.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  
  List<Restaurant> _restaurants = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadRestaurants();
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _apiService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des restaurants: $e');
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final titreController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    final allergenesController = TextEditingController();
    int? selectedRestaurantId;

    // Initialiser la date à aujourd'hui
    final today = DateTime.now();
    dateController.text = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un menu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre du menu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: today,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La date est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: allergenesController,
                decoration: const InputDecoration(
                  labelText: 'Allergènes (séparés par des virgules)',
                  border: OutlineInputBorder(),
                  hintText: 'ex: gluten, lactose, fruits de mer',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedRestaurantId,
                decoration: const InputDecoration(
                  labelText: 'Restaurant',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                items: _restaurants.map((restaurant) {
                  return DropdownMenuItem(
                    value: restaurant.id,
                    child: Text(restaurant.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRestaurantId = value;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Le restaurant est requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && selectedRestaurantId != null) {
                Navigator.of(context).pop({
                  'titre': titreController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'date': dateController.text,
                  'allergenes': allergenesController.text.trim(),
                  'restaurantId': selectedRestaurantId,
                });
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createMenu(result);
    }
  }

  Future<void> _createMenu(Map<String, dynamic> data) async {
    try {
      final allergenes = data['allergenes'].toString().isEmpty 
          ? <String>[]
          : data['allergenes'].toString().split(',').map((e) => e.trim()).toList();

      final menu = await _apiService.createMenu(
        titre: data['titre'],
        description: data['description'].isEmpty ? null : data['description'],
        date: DateTime.parse(data['date']),
        allergenes: allergenes,
        restaurantId: data['restaurantId'],
      );

      // Mettre à jour le cache et forcer le rafraîchissement
      final cacheService = ref.read(menuCacheServiceProvider);
      cacheService.updateMenuInCache(menu);
      ref.read(menuRefreshProvider.notifier).state++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu "${menu.titre}" créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(Menu menu) async {
    final formKey = GlobalKey<FormState>();
    final titreController = TextEditingController(text: menu.titre);
    final descriptionController = TextEditingController(text: menu.description ?? '');
    final dateController = TextEditingController(text: menu.date.toIso8601String().split('T')[0]);
    final allergenesController = TextEditingController(text: menu.allergenes.join(', '));
    int selectedRestaurantId = menu.restaurantId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${menu.titre}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre du menu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: menu.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La date est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: allergenesController,
                decoration: const InputDecoration(
                  labelText: 'Allergènes (séparés par des virgules)',
                  border: OutlineInputBorder(),
                  hintText: 'ex: gluten, lactose, fruits de mer',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedRestaurantId,
                decoration: const InputDecoration(
                  labelText: 'Restaurant',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                items: _restaurants.map((restaurant) {
                  return DropdownMenuItem(
                    value: restaurant.id,
                    child: Text(restaurant.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRestaurantId = value!;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Le restaurant est requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop({
                  'titre': titreController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'date': dateController.text,
                  'allergenes': allergenesController.text.trim(),
                  'restaurantId': selectedRestaurantId,
                });
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateMenu(menu.id, result);
    }
  }

  Future<void> _updateMenu(int id, Map<String, dynamic> data) async {
    try {
      print('🔄 Début de la modification du menu $id');
      final allergenes = data['allergenes'].toString().isEmpty 
          ? <String>[]
          : data['allergenes'].toString().split(',').map((e) => e.trim()).toList();

      final updatedMenu = await _apiService.updateMenu(
        id: id,
        titre: data['titre'],
        description: data['description'].isEmpty ? null : data['description'],
        date: DateTime.parse(data['date']),
        allergenes: allergenes,
        restaurantId: data['restaurantId'],
      );

      print('✅ Menu modifié avec succès: ${updatedMenu.titre}');
      
      // Mettre à jour le cache automatiquement
      final cacheService = ref.read(menuCacheServiceProvider);
      cacheService.updateMenuInCache(updatedMenu);
      
      // Forcer le rafraîchissement du provider Riverpod
      ref.read(menuRefreshProvider.notifier).state++;

      print('✅ Interface mise à jour automatiquement');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu "${updatedMenu.titre}" modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la modification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(Menu menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le menu "${menu.titre}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMenu(menu.id);
    }
  }

  Future<void> _deleteMenu(int id) async {
    try {
      final success = await _apiService.deleteMenu(id);
      
      if (success) {
        // Supprimer du cache et forcer le rafraîchissement
        final cacheService = ref.read(menuCacheServiceProvider);
        cacheService.removeMenuFromCache(id);
        ref.read(menuRefreshProvider.notifier).state++;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu supprimé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getRestaurantName(int restaurantId) {
    final restaurant = _restaurants.firstWhere(
      (r) => r.id == restaurantId,
      orElse: () => Restaurant(id: 0, nom: 'Inconnu', quartier: ''),
    );
    return restaurant.nom;
  }

  bool get _canManageMenus {
    return _userRole == 'admin' || _userRole == 'restaurateur';
  }

  @override
  Widget build(BuildContext context) {
    final menusAsync = ref.watch(menusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Menus'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadRestaurants,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: menusAsync.when(
        data: (menus) => _buildMenuList(menus),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
        ),
      ),
      floatingActionButton: _canManageMenus
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMenuList(List<Menu> menus) {
    if (menus.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun menu trouvé'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(
                Icons.menu_book,
                color: Colors.white,
              ),
            ),
            title: Text(
              menu.titre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (menu.description != null)
                  Text(menu.description!),
                Text('Date: ${menu.formattedDate}'),
                Text('Restaurant: ${_getRestaurantName(menu.restaurantId)}'),
                if (menu.allergenes.isNotEmpty)
                  Text('Allergènes: ${menu.allergenes.join(', ')}'),
              ],
            ),
            trailing: _canManageMenus
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(menu);
                          break;
                        case 'delete':
                          _showDeleteDialog(menu);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: () {
              // Navigation vers les détails du menu
              // TODO: Implémenter la navigation
            },
          ),
        );
      },
    );
  }
}
