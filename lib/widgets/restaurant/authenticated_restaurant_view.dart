import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'restaurant_images_widget.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/restaurant.dart';

/// Vue authentifiée pour les restaurants - accessible aux utilisateurs connectés
class AuthenticatedRestaurantView extends ConsumerStatefulWidget {
  final int? highlightRestaurantId;
  
  const AuthenticatedRestaurantView({super.key, this.highlightRestaurantId});

  @override
  ConsumerState<AuthenticatedRestaurantView> createState() => _AuthenticatedRestaurantViewState();
}

class _AuthenticatedRestaurantViewState extends ConsumerState<AuthenticatedRestaurantView> {
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
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Restaurants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout de restaurant (pour les administrateurs)
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              if (authState is AuthenticatedAuthState && authState.role == 'admin') {
                return ElevatedButton.icon(
                  onPressed: () {
                    context.push('/admin/restaurant/new');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('🏪 Ajouter un restaurant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
        data: (restaurants) => _buildRestaurantsContent(context, restaurants),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur lors du chargement des restaurants: $error'),
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
      ),
    );
  }

  Widget _buildRestaurantsContent(BuildContext context, List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun restaurant trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Si un restaurant est mis en évidence, faire défiler vers lui
    if (widget.highlightRestaurantId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _restaurantKeys[widget.highlightRestaurantId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return _useGalleryMode
        ? _buildGalleryMode(context, restaurants)
        : _buildRestaurantsList(context, restaurants);
  }

  Widget _buildGalleryMode(BuildContext context, List<Restaurant> restaurants) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return _buildRestaurantCard(context, restaurant);
      },
    );
  }

  Widget _buildRestaurantsList(BuildContext context, List<Restaurant> restaurants) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return _buildRestaurantCard(context, restaurant);
      },
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/restaurants/${restaurant.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: _restaurantKeys[restaurant.id] = GlobalKey(),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image du restaurant
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RestaurantImagesWidget(
                  images: restaurant.allImages,
                  width: 120,
                  height: 120,
                  showAllImages: true, // Grille horizontale n×1 avec scroll
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations du restaurant
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.adresse ?? 'Adresse non disponible',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.quartier,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Ouvert maintenant',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bouton d'action
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      context.push('/restaurants/${restaurant.id}');
                    },
                    icon: const Icon(Icons.arrow_forward_ios),
                    tooltip: 'Voir les détails',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/menus/restaurant/${restaurant.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Voir les menus'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
