import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RestaurantManagementScreen extends ConsumerStatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  ConsumerState<RestaurantManagementScreen> createState() => _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState extends ConsumerState<RestaurantManagementScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;
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
    print('🔄 Début du chargement des restaurants');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final restaurants = await _apiService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
      
      print('✅ Restaurants chargés: ${_restaurants.length} restaurants');
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final quartierController = TextEditingController();
    final adresseController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un restaurant'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du restaurant',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quartierController,
                decoration: const InputDecoration(
                  labelText: 'Quartier',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le quartier est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                ),
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
                  'nom': nomController.text.trim(),
                  'quartier': quartierController.text.trim(),
                  'adresse': adresseController.text.trim(),
                });
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createRestaurant(result);
    }
  }

  Future<void> _createRestaurant(Map<String, String> data) async {
    try {
      final restaurant = await _apiService.createRestaurant(
        nom: data['nom']!,
        quartier: data['quartier']!,
        adresse: data['adresse']!.isEmpty ? null : data['adresse'],
      );

      // Rafraîchir les données depuis le serveur
      await _loadRestaurants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurant "${restaurant.nom}" créé avec succès !'),
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

  Future<void> _showEditDialog(Restaurant restaurant) async {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: restaurant.nom);
    final quartierController = TextEditingController(text: restaurant.quartier);
    final adresseController = TextEditingController(text: restaurant.adresse ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${restaurant.nom}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du restaurant',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quartierController,
                decoration: const InputDecoration(
                  labelText: 'Quartier',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le quartier est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                ),
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
                  'nom': nomController.text.trim(),
                  'quartier': quartierController.text.trim(),
                  'adresse': adresseController.text.trim(),
                });
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateRestaurant(restaurant.id, result);
    }
  }

  Future<void> _updateRestaurant(int id, Map<String, String> data) async {
    try {
      print('🔄 Début de la modification du restaurant $id');
      final updatedRestaurant = await _apiService.updateRestaurant(
        id: id,
        nom: data['nom'],
        quartier: data['quartier'],
        adresse: data['adresse']!.isEmpty ? null : data['adresse'],
      );

      print('✅ Restaurant modifié avec succès: ${updatedRestaurant.nom}');
      print('🔄 Rafraîchissement des données...');

      // Mettre à jour l'élément dans la liste locale
      setState(() {
        final index = _restaurants.indexWhere((r) => r.id == id);
        if (index != -1) {
          _restaurants[index] = updatedRestaurant;
          print('✅ Restaurant mis à jour dans la liste locale');
        }
      });

      // Attendre un peu avant de rafraîchir pour s'assurer que l'API a traité la modification
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Rafraîchir les données depuis le serveur
      await _loadRestaurants();

      print('✅ Données rafraîchies');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurant "${updatedRestaurant.nom}" modifié avec succès !'),
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

  Future<void> _showDeleteDialog(Restaurant restaurant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le restaurant "${restaurant.nom}" ?\n\n'
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
      await _deleteRestaurant(restaurant.id);
    }
  }

  Future<void> _deleteRestaurant(int id) async {
    try {
      final success = await _apiService.deleteRestaurant(id);
      
      if (success) {
        // Rafraîchir les données depuis le serveur
        await _loadRestaurants();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant supprimé avec succès !'),
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

  bool get _canManageRestaurants {
    return _userRole == 'admin' || _userRole == 'restaurateur';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Restaurants'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_canManageRestaurants)
            IconButton(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _canManageRestaurants
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun restaurant trouvé'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                restaurant.nom[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              restaurant.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quartier: ${restaurant.quartier}'),
                if (restaurant.adresse != null)
                  Text('Adresse: ${restaurant.adresse}'),
                if (restaurant.imagesCount > 0)
                  Text('${restaurant.imagesCount} image(s)'),
              ],
            ),
            trailing: _canManageRestaurants
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(restaurant);
                          break;
                        case 'delete':
                          _showDeleteDialog(restaurant);
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
              // Navigation vers les détails du restaurant
              // TODO: Implémenter la navigation
            },
          ),
        );
      },
    );
  }
}
