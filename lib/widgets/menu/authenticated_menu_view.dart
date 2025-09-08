import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'menu_image_widget.dart';
import '../../providers/menu_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu.dart';
import '../../models/search_criteria.dart';

/// Vue authentifiée pour les menus - accessible aux utilisateurs connectés
class AuthenticatedMenuView extends ConsumerStatefulWidget {
  final int? restaurantId;
  
  const AuthenticatedMenuView({super.key, this.restaurantId});

  @override
  ConsumerState<AuthenticatedMenuView> createState() => _AuthenticatedMenuViewState();
}

class _AuthenticatedMenuViewState extends ConsumerState<AuthenticatedMenuView> {
  final TextEditingController _titreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Réinitialiser les filtres à chaque fois qu'on revient sur l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.restaurantId != null) {
        // Si on vient d'un restaurant, garder seulement ce filtre et réinitialiser le reste
        ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria(
          restaurantId: widget.restaurantId,
        );
      } else {
        // Si on vient de la navigation, tout réinitialiser
        ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
      }
      _syncControllersWithFilters();
    });
  }

  /// Synchroniser les contrôleurs avec les filtres actuels
  void _syncControllersWithFilters() {
    final searchCriteria = ref.read(searchCriteriaProvider);
    _titreController.text = searchCriteria.titre ?? '';
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Menus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout de menu (pour les administrateurs et restaurateurs)
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              if (authState is AuthenticatedAuthState && 
                  ['admin', 'restaurateur'].contains(authState.role)) {
                return ElevatedButton.icon(
                  onPressed: () {
                    context.push('/admin/menu/new');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('🍽️ Ajouter un menu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Section de recherche et filtres (toujours visible sur desktop)
          if (isLargeScreen) ...[
            SizedBox(
              width: 300,
              child: _buildSearchSection(context),
            ),
            const VerticalDivider(width: 1),
          ],
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Section de recherche mobile (masquée sur desktop)
                if (!isLargeScreen) _buildSearchSection(context),
                
                // Liste des menus
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final menusAsync = ref.watch(filteredMenusProvider);
                      return menusAsync.when(
                        data: (menus) => _buildMenusList(context, menus),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Erreur lors du chargement des menus: $error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.invalidate(filteredMenusProvider);
                                },
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rechercher un menu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Champ de recherche par titre
          TextFormField(
            controller: _titreController,
            decoration: const InputDecoration(
              labelText: 'Titre du menu',
              hintText: 'Ex: Menu Gastronomique',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final currentCriteria = ref.read(searchCriteriaProvider);
              ref.read(searchCriteriaProvider.notifier).state = currentCriteria.copyWith(
                titre: value.isEmpty ? null : value,
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par restaurant
          Consumer(
            builder: (context, ref, child) {
              final restaurantsAsync = ref.watch(restaurantsProvider);
              return restaurantsAsync.when(
                data: (restaurants) => DropdownButtonFormField<int?>(
                  value: ref.watch(searchCriteriaProvider).restaurantId,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant',
                    prefixIcon: Icon(Icons.restaurant),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tous les restaurants'),
                    ),
                    ...restaurants.map((restaurant) => DropdownMenuItem<int?>(
                      value: restaurant.id,
                      child: Text(restaurant.nom),
                    )),
                  ],
                  onChanged: (value) {
                    final currentCriteria = ref.read(searchCriteriaProvider);
                    ref.read(searchCriteriaProvider.notifier).state = currentCriteria.copyWith(
                      restaurantId: value,
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Erreur: $error'),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bouton de réinitialisation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                _titreController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Réinitialiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenusList(BuildContext context, List<Menu> menus) {
    if (menus.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun menu trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(context, menu);
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, Menu menu) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails du menu
          context.push('/menu/${menu.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du menu
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: MenuImageWidget(
                  imageUrl: menu.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            
            // Informations du menu
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${menu.prix}€',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restaurant ID: ${menu.restaurantId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
