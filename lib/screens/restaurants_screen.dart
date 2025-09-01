import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/restaurant_images_widget.dart';
import '../providers/restaurant_provider.dart';
import '../models/restaurant.dart';
import '../widgets/restaurant_gallery_widget.dart';
import '../services/api_service.dart';
import '../widgets/auth_guard_wrapper.dart';
import '../widgets/public_restaurant_view.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  final int? highlightRestaurantId;
  
  const RestaurantsScreen({super.key, this.highlightRestaurantId});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _restaurantKeys = {};
  bool _useGalleryMode = false; // Nouvel état pour basculer entre les modes

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRestaurantsScreen(context).authGuard(
      pageType: 'admin', // Les restaurants nécessitent un accès admin pour les fonctionnalités complètes
      publicView: PublicRestaurantView(highlightRestaurantId: widget.highlightRestaurantId), // Vue publique si token invalide
      requireAuth: true,
      customMessage: 'Accès aux restaurants nécessite une authentification valide',
    );
  }

  Widget _buildRestaurantsScreen(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Restaurants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout de restaurant (pour les administrateurs)
          ElevatedButton.icon(
            onPressed: () {
              context.push('/admin/restaurant/new');
            },
            icon: const Icon(Icons.add),
            label: const Text('🏪 Ajouter un restaurant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          // Toggle pour basculer entre les modes d'affichage
          IconButton(
            onPressed: () {
              setState(() {
                _useGalleryMode = !_useGalleryMode;
              });
            },
            icon: Icon(
              _useGalleryMode ? Icons.view_carousel : Icons.view_agenda,
            ),
            tooltip: _useGalleryMode ? 'Mode liste' : 'Mode galerie',
          ),
        ],
      ),
      body: restaurantsAsync.when(
        data: (restaurants) {
          // Créer les clés pour chaque restaurant si nécessaire
          for (final restaurant in restaurants) {
            _restaurantKeys.putIfAbsent(restaurant.id, () => GlobalKey());
          }
          
          // Programmer le scroll après que les widgets soient construits
          if (widget.highlightRestaurantId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToRestaurant(widget.highlightRestaurantId!);
            });
          }
          
          return _buildRestaurantsList(restaurants);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorWidget(error, ref),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _buildRestaurantsList(List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Text(
          'Aucun restaurant disponible',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        final key = _restaurantKeys[restaurant.id]!;
        return _buildRestaurantCard(context, restaurant, key);
      },
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant, GlobalKey key) {
    final isHighlighted = widget.highlightRestaurantId == restaurant.id;
    
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isHighlighted ? 8 : 4,
      color: isHighlighted ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images du restaurant (gère 0 à n images) - SANS InkWell
          _useGalleryMode
              ? RestaurantGalleryWidget(
                  images: restaurant.allImages,
                  width: double.infinity,
                  height: 240, // Hauteur augmentée pour la galerie
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  margin: const EdgeInsets.all(0),
                  imageHeight: 140, // Hauteur d'image réduite pour mieux s'adapter
                  imageSpacing: 12, // Espacement réduit
                )
              : RestaurantImagesWidget(
                  images: restaurant.allImages,
                  width: double.infinity,
                  height: 200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  enableHorizontalScroll: true, // Activer la galerie scrollable
                  showMultipleImages: true, // Activer l'affichage multiple
                  margin: const EdgeInsets.all(0),
                ),
          
          // Debug: Afficher les informations sur les images
          if (restaurant.allImages.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                'Debug: ${restaurant.allImages.length} images trouvées - Mode: ${_useGalleryMode ? "Galerie" : "PageView"}',
                style: const TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
          ],
          
          // Partie cliquable de la carte (SANS les images)
          InkWell(
            onTap: () {
              context.go('/menus/restaurant/${restaurant.id}');
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            hoverColor: Colors.grey.withValues(alpha: 0.1),
            splashColor: Colors.grey.withValues(alpha: 0.3),
            highlightColor: Colors.grey.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.nom,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Boutons d'administration
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {
                              context.push('/admin/restaurant/edit/${restaurant.id}');
                            },
                            tooltip: 'Modifier le restaurant',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => _showDeleteRestaurantDialog(restaurant),
                            tooltip: 'Supprimer le restaurant',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.quartier,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (restaurant.adresse != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.adresse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (restaurant.horaires != null && restaurant.horaires!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Horaires :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHoraires(restaurant.horaires!),
                  ],
                  if (restaurant.equipements != null && restaurant.equipements!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Équipements :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildEquipements(restaurant.equipements!),
                  ],
                  const SizedBox(height: 16),
                  // Indicateur visuel que la carte est cliquable
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Voir les menus',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToRestaurant(int restaurantId) {
    final key = _restaurantKeys[restaurantId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position relative dans la vue (20% du haut)
      );
    }
  }

  Widget _buildHoraires(List<Horaire> horaires) {
    return Column(
      children: horaires.map((horaire) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  horaire.jour,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text('${horaire.ouverture} - ${horaire.fermeture}'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEquipements(List<Equipement> equipements) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: equipements.map((equipement) {
        return Chip(
          label: Text(
            equipement.nom,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.green.shade100,
        );
      }).toList(),
    );
  }

  Widget _buildErrorWidget(Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(restaurantsProvider);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
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
            child: const Text('Supprimer'),
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
          const SnackBar(
            content: Text('Restaurant supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
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
}