import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import 'restaurant_images_widget.dart';

/// Vue publique des restaurants
class PublicRestaurantView extends ConsumerWidget {
  final int? highlightRestaurantId;
  
  const PublicRestaurantView({super.key, this.highlightRestaurantId});

  /// Gérer la connexion
  void _handleLogin(BuildContext context) {
    // Rediriger vers l'écran de connexion
    context.go('/profil?view=login');
  }

  /// Gérer la déconnexion
  void _handleLogout(WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
    print('🚪 [PublicRestaurantView] Déconnexion effectuée');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants - Vue Publique'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton de connexion/déconnexion dynamique
          ElevatedButton.icon(
            onPressed: authState.isAuthenticated ? () => _handleLogout(ref) : () => _handleLogin(context),
            icon: Icon(authState.isAuthenticated ? Icons.logout : Icons.login),
            label: Text(authState.isAuthenticated ? 'Se déconnecter' : 'Se connecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: authState.isAuthenticated ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message informatif adaptatif
          if (!authState.isAuthenticated)
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue publique des restaurants',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connectez-vous pour accéder aux fonctionnalités complètes',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des restaurants
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) => _buildPublicRestaurantsList(context, restaurants),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicRestaurantsList(BuildContext context, List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun restaurant disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        final isHighlighted = highlightRestaurantId != null && restaurant.id == highlightRestaurantId;

        return Card(
          margin: EdgeInsets.only(
            bottom: 16,
            left: isHighlighted ? 8 : 0,
            right: isHighlighted ? 8 : 0,
          ),
          elevation: isHighlighted ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isHighlighted 
              ? BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du restaurant
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: RestaurantImagesWidget(
                    images: restaurant.allImages,
                    width: double.infinity,
                    height: 200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    fit: BoxFit.cover,
                    showMultipleImages: true,
                    enableHorizontalScroll: true,
                  ),
                ),
              ),
              // Informations du restaurant
              Padding(
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
                        if (isHighlighted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sélectionné',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    // Note: Le modèle Restaurant n'a pas de champ description pour l'instant
                    // if (restaurant.description != null) ...[
                    //   const SizedBox(height: 12),
                    //   Text(
                    //     restaurant.description!,
                    //     style: const TextStyle(fontSize: 16),
                    //   ),
                    // ],
                    const SizedBox(height: 12),
                    // Bouton pour voir les menus (version publique)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter la navigation vers les menus du restaurant
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navigation vers les menus de ${restaurant.nom} à implémenter')),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Voir les menus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
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
    );
  }
}
