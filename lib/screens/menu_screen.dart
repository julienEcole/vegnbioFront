import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/menu_image_widget.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/menu.dart';
import '../models/restaurant.dart';
import '../models/search_criteria.dart';
import '../services/api_service.dart';
import '../services/token_validator_service.dart';

import '../widgets/public_menu_view.dart';
import '../widgets/auth_guard_wrapper.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int? restaurantId;
  
  const MenuScreen({super.key, this.restaurantId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
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
    return _buildMenuScreen(context).authGuard(
      pageType: 'admin', // Les menus nécessitent un accès admin pour les fonctionnalités complètes
      publicView: PublicMenuView(), // Vue publique si token invalide
      requireAuth: true,
      customMessage: 'Accès aux menus nécessite une authentification valide',
    );
  }

  Widget _buildMenuScreen(BuildContext context) {
    final menusAsync = ref.watch(filteredMenusProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 800;
    final bool isMediumScreen = screenSize.width > 600;

    // Déterminer le titre de la page en fonction du contexte
    String pageTitle = 'Nos Menus';
    if (widget.restaurantId != null) {
      final restaurant = restaurantsAsync.when(
        data: (restaurants) => restaurants.where((r) => r.id == widget.restaurantId).firstOrNull,
        loading: () => null,
        error: (_, __) => null,
      );
      if (restaurant != null) {
        pageTitle = 'Menus - ${restaurant.nom}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout de menu (pour les administrateurs)
          if (isMediumScreen)
            ElevatedButton.icon(
              onPressed: () {
                context.push('/admin/menu/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('🍽️ Ajouter un menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showFiltersModal(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Filtres', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: _refreshMenus,
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Rafraîchir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
           // Affichage des filtres actifs en haut (toujours visible)
           _buildActiveFiltersDisplay(),
           // Liste des menus
          Expanded(
            child: menusAsync.when(
              data: (menus) => restaurantsAsync.when(
                data: (restaurants) => _buildMenusList(menus, restaurants),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget(error, ref),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error, ref),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _buildActiveFiltersDisplay() {
    final searchCriteria = ref.watch(searchCriteriaProvider);
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    // Si aucun filtre n'est actif, ne rien afficher
    if (searchCriteria.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSmallScreen) ...[
            // Version mobile : disposition verticale
            Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filtres actifs :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _showFiltersModal(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _titreController.clear();
                    ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Effacer tout'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Version desktop : disposition horizontale
            Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filtres actifs :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showFiltersModal(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _titreController.clear();
                    ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Effacer tout'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Filtre par titre
              if (searchCriteria.titre != null && searchCriteria.titre!.isNotEmpty)
                _buildFilterChip(
                  'Titre: ${searchCriteria.titre}',
                  Colors.blue.shade100,
                  () => _updateSearchCriteria(titre: ''),
                ),
              
              // Filtre par restaurant
              if (searchCriteria.restaurantId != null)
                _buildFilterChip(
                  'Restaurant sélectionné',
                  Colors.green.shade100,
                  () => _updateSearchCriteria(restaurantId: null),
                ),
              
              // Allergènes exclus
              ...searchCriteria.allergenesExclus.map((allergene) => 
                _buildFilterChip(
                  'Exclure: $allergene',
                  Colors.red.shade100,
                  () => _updateSearchCriteria(
                    allergenesExclus: searchCriteria.allergenesExclus
                        .where((a) => a != allergene)
                        .toList(),
                  ),
                ),
              ),
              
              // Allergènes inclus
              ...searchCriteria.allergenesInclus.map((allergene) => 
                _buildFilterChip(
                  'Inclure: $allergene',
                  Colors.green.shade100,
                  () => _updateSearchCriteria(
                    allergenesInclus: searchCriteria.allergenesInclus
                        .where((a) => a != allergene)
                        .toList(),
                  ),
                ),
              ),
              
              // Produits exclus
              ...searchCriteria.produitsExclus.map((produit) => 
                _buildFilterChip(
                  'Exclure: $produit',
                  Colors.red.shade100,
                  () => _updateSearchCriteria(
                    produitsExclus: searchCriteria.produitsExclus
                        .where((p) => p != produit)
                        .toList(),
                  ),
                ),
              ),
              
              // Produits inclus
              ...searchCriteria.produitsInclus.map((produit) => 
                _buildFilterChip(
                  'Inclure: $produit',
                  Colors.green.shade100,
                  () => _updateSearchCriteria(
                    produitsInclus: searchCriteria.produitsInclus
                        .where((p) => p != produit)
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFiltersModal(BuildContext context) {
    // Synchroniser les contrôleurs avec les filtres actuels avant d'ouvrir la modale
    _syncControllersWithFilters();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersModal(),
    );
  }

  Widget _buildFiltersModal() {
    final searchCriteria = ref.watch(searchCriteriaProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    return Container(
      height: MediaQuery.of(context).size.height * (isSmallScreen ? 0.9 : 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // En-tête du modal
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.green, size: 24),
                SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                Text(
                  'Filtres de recherche',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Contenu du formulaire
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  // Ligne 1: Titre et Restaurant
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
            controller: _titreController,
            decoration: const InputDecoration(
                            labelText: 'Titre du menu',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _updateSearchCriteria(titre: value),
          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: restaurantsAsync.when(
            data: (restaurants) => DropdownButtonFormField<int>(
              value: searchCriteria.restaurantId,
              decoration: const InputDecoration(
                              labelText: 'Restaurant',
                prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Tous les restaurants'),
                ),
                ...restaurants.map((restaurant) => DropdownMenuItem<int>(
                  value: restaurant.id,
                  child: Text(restaurant.nom),
                )),
              ],
              onChanged: (value) {
                ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria(
                  titre: searchCriteria.titre,
                  restaurantId: value,
                );
              },
            ),
                          loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Ligne 2: Allergènes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Exclure les allergènes :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final availableAllergenesAsync = ref.watch(availableAllergenesForRestaurantProvider);
              
              return availableAllergenesAsync.when(
                data: (availableAllergenes) {
                  if (availableAllergenes.isEmpty) {
                                      return Text('Aucun allergène disponible', style: TextStyle(color: Colors.grey, fontSize: 14));
                  }
                  
                  return Wrap(
                    spacing: 8,
                                      runSpacing: 8,
                    children: availableAllergenes.map((allergene) {
                      final isSelected = searchCriteria.allergenesExclus.contains(allergene);
                      return FilterChip(
                        label: Text(allergene),
                        selected: isSelected,
                        selectedColor: Colors.red.shade100,
                        onSelected: (selected) {
                          if (selected) {
                            _updateSearchCriteria(
                              allergenesExclus: [...searchCriteria.allergenesExclus, allergene],
                            );
                          } else {
                            _updateSearchCriteria(
                              allergenesExclus: searchCriteria.allergenesExclus.where((a) => a != allergene).toList(),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                },
                                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                                  error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✅ Inclure les allergènes :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, child) {
                                final availableAllergenesAsync = ref.watch(availableAllergenesForRestaurantProvider);
                                
                                return availableAllergenesAsync.when(
                                  data: (availableAllergenes) {
                                    if (availableAllergenes.isEmpty) {
                                      return Text('Aucun allergène disponible', style: TextStyle(color: Colors.grey, fontSize: 14));
                                    }
                                    
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: availableAllergenes.map((allergene) {
                                        final isSelected = searchCriteria.allergenesInclus.contains(allergene);
                                        return FilterChip(
                                          label: Text(allergene),
                                          selected: isSelected,
                                          selectedColor: Colors.green.shade100,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _updateSearchCriteria(
                                                allergenesInclus: [...searchCriteria.allergenesInclus, allergene],
                                              );
                                            } else {
                                              _updateSearchCriteria(
                                                allergenesInclus: searchCriteria.allergenesInclus.where((a) => a != allergene).toList(),
                                              );
                                            }
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
                                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                                  error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Ligne 3: Produits
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🚫 Exclure les produits :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, child) {
                                final availableProduitsAsync = ref.watch(availableProduitsForRestaurantProvider);
                                
                                return availableProduitsAsync.when(
                                  data: (availableProduits) {
                                    if (availableProduits.isEmpty) {
                                      return Text('Aucun produit disponible', style: TextStyle(color: Colors.grey, fontSize: 14));
                                    }
                                    
                                    return Container(
                                      height: 120,
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: availableProduits.map((produit) {
                                            final isSelected = searchCriteria.produitsExclus.contains(produit);
                                            return FilterChip(
                                              label: Text(produit),
                                              selected: isSelected,
                                              selectedColor: Colors.red.shade100,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  _updateSearchCriteria(
                                                    produitsExclus: [...searchCriteria.produitsExclus, produit],
                                                  );
                                                } else {
                                                  _updateSearchCriteria(
                                                    produitsExclus: searchCriteria.produitsExclus.where((p) => p != produit).toList(),
                                                  );
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                                  error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🍽️ Inclure les produits :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, child) {
                                final availableProduitsAsync = ref.watch(availableProduitsForRestaurantProvider);
                                
                                return availableProduitsAsync.when(
                                  data: (availableProduits) {
                                    if (availableProduits.isEmpty) {
                                      return Text('Aucun produit disponible', style: TextStyle(color: Colors.grey, fontSize: 14));
                                    }
                                    
                                    return Container(
                                      height: 120,
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: availableProduits.map((produit) {
                                            final isSelected = searchCriteria.produitsInclus.contains(produit);
                                            return FilterChip(
                                              label: Text(produit),
                                              selected: isSelected,
                                              selectedColor: Colors.green.shade100,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  _updateSearchCriteria(
                                                    produitsInclus: [...searchCriteria.produitsInclus, produit],
                                                  );
                                                } else {
                                                  _updateSearchCriteria(
                                                    produitsInclus: searchCriteria.produitsInclus.where((p) => p != produit).toList(),
                                                  );
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                                  error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _titreController.clear();
                            ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Effacer tout'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Rechercher',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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

  Widget _buildFilterChip(String label, Color backgroundColor, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final searchCriteria = ref.watch(searchCriteriaProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1: Titre et Restaurant (côte à côte)
          Row(
            children: [
              // Recherche par titre
              Expanded(
                child: TextField(
                  controller: _titreController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _updateSearchCriteria(titre: value),
                ),
              ),
              const SizedBox(width: 12),
              // Sélection de restaurant
              Expanded(
                child: restaurantsAsync.when(
                  data: (restaurants) => DropdownButtonFormField<int>(
                    value: searchCriteria.restaurantId,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant',
                      prefixIcon: Icon(Icons.restaurant, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Tous'),
                      ),
                      ...restaurants.map((restaurant) => DropdownMenuItem<int>(
                        value: restaurant.id,
                        child: Text(restaurant.nom),
                      )),
                    ],
                    onChanged: (value) {
                      ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria(
                        titre: searchCriteria.titre,
                        restaurantId: value,
                      );
                    },
                  ),
                  loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Ligne 2: Allergènes (côte à côte)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Allergènes à exclure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚫 Exclure :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, child) {
                        final availableAllergenesAsync = ref.watch(availableAllergenesForRestaurantProvider);
                        
                        return availableAllergenesAsync.when(
                          data: (availableAllergenes) {
                            if (availableAllergenes.isEmpty) {
                              return Text('Aucun allergène', style: TextStyle(color: Colors.grey, fontSize: 12));
                            }
                            
                            return Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: availableAllergenes.map((allergene) {
                                final isSelected = searchCriteria.allergenesExclus.contains(allergene);
                                return FilterChip(
                                  label: Text(allergene, style: const TextStyle(fontSize: 11)),
                                  selected: isSelected,
                                  selectedColor: Colors.red.shade100,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _updateSearchCriteria(
                                        allergenesExclus: [...searchCriteria.allergenesExclus, allergene],
                                      );
                                    } else {
                                      _updateSearchCriteria(
                                        allergenesExclus: searchCriteria.allergenesExclus.where((a) => a != allergene).toList(),
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator())),
                          error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
          // Allergènes à inclure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ Inclure :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
          Consumer(
            builder: (context, ref, child) {
              final availableAllergenesAsync = ref.watch(availableAllergenesForRestaurantProvider);
              
              return availableAllergenesAsync.when(
                data: (availableAllergenes) {
                  if (availableAllergenes.isEmpty) {
                              return Text('Aucun allergène', style: TextStyle(color: Colors.grey, fontSize: 12));
                  }
                  
                  return Wrap(
                              spacing: 4,
                    runSpacing: 4,
                    children: availableAllergenes.map((allergene) {
                      final isSelected = searchCriteria.allergenesInclus.contains(allergene);
                      return FilterChip(
                                  label: Text(allergene, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: Colors.green.shade100,
                        onSelected: (selected) {
                          if (selected) {
                            _updateSearchCriteria(
                              allergenesInclus: [...searchCriteria.allergenesInclus, allergene],
                            );
                          } else {
                            _updateSearchCriteria(
                              allergenesInclus: searchCriteria.allergenesInclus.where((a) => a != allergene).toList(),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                },
                          loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator())),
                          error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Ligne 3: Produits (côte à côte)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Produits à exclure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚫 Produits exclus :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, child) {
                        final availableProduitsAsync = ref.watch(availableProduitsForRestaurantProvider);
                        
                        return availableProduitsAsync.when(
                          data: (availableProduits) {
                            if (availableProduits.isEmpty) {
                              return Text('Aucun produit', style: TextStyle(color: Colors.grey, fontSize: 12));
                            }
                            
                            return Container(
                              height: 80,
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: availableProduits.map((produit) {
                                    final isSelected = searchCriteria.produitsExclus.contains(produit);
                                    return FilterChip(
                                      label: Text(produit, style: const TextStyle(fontSize: 10)),
                                      selected: isSelected,
                                      selectedColor: Colors.red.shade100,
                                      onSelected: (selected) {
                                        if (selected) {
                                          _updateSearchCriteria(
                                            produitsExclus: [...searchCriteria.produitsExclus, produit],
                                          );
                                        } else {
                                          _updateSearchCriteria(
                                            produitsExclus: searchCriteria.produitsExclus.where((p) => p != produit).toList(),
                                          );
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                          error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Produits à inclure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🍽️ Produits inclus :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, child) {
                        final availableProduitsAsync = ref.watch(availableProduitsForRestaurantProvider);
                        
                        return availableProduitsAsync.when(
                          data: (availableProduits) {
                            if (availableProduits.isEmpty) {
                              return Text('Aucun produit', style: TextStyle(color: Colors.grey, fontSize: 12));
                            }
                            
                            return Container(
                              height: 80,
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: availableProduits.map((produit) {
                                    final isSelected = searchCriteria.produitsInclus.contains(produit);
                                    return FilterChip(
                                      label: Text(produit, style: const TextStyle(fontSize: 10)),
                                      selected: isSelected,
                                      selectedColor: Colors.green.shade100,
                                      onSelected: (selected) {
                                        if (selected) {
                                          _updateSearchCriteria(
                                            produitsInclus: [...searchCriteria.produitsInclus, produit],
                                          );
                                        } else {
                                          _updateSearchCriteria(
                                            produitsInclus: searchCriteria.produitsInclus.where((p) => p != produit).toList(),
                                          );
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                          error: (error, stack) => Text('Erreur: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Ligne 4: Boutons d'action
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _titreController.clear();
                  ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Effacer tout'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${searchCriteria.allergenesExclus.length} exclus, ${searchCriteria.allergenesInclus.length} inclus, ${searchCriteria.produitsExclus.length} produits exclus, ${searchCriteria.produitsInclus.length} produits inclus',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateSearchCriteria({
    String? titre,
    int? restaurantId,
    List<String>? allergenesExclus,
    List<String>? allergenesInclus,
    List<String>? produitsExclus,
    List<String>? produitsInclus,
  }) {
    final currentCriteria = ref.read(searchCriteriaProvider);
    
    ref.read(searchCriteriaProvider.notifier).state = currentCriteria.copyWith(
      titre: titre ?? (titre == '' ? null : currentCriteria.titre),
      restaurantId: restaurantId ?? currentCriteria.restaurantId,
      allergenesExclus: allergenesExclus ?? currentCriteria.allergenesExclus,
      allergenesInclus: allergenesInclus ?? currentCriteria.allergenesInclus,
      produitsExclus: produitsExclus ?? currentCriteria.produitsExclus,
      produitsInclus: produitsInclus ?? currentCriteria.produitsInclus,
    );
  }

  Widget _buildMenusList(List<Menu> menus, List<Restaurant> restaurants) {
    if (menus.isEmpty) {
      return const Center(
        child: Text(
          'Aucun menu disponible',
          style: TextStyle(fontSize: 18),
        ),
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
        return _buildMenuCard(menu, restaurant);
      },
    );
  }

  Widget _buildMenuCard(Menu menu, Restaurant? restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: LayoutBuilder(
          key: ValueKey('menu_layout'), // Clé simple pour l'animation
          builder: (context, constraints) {
            // Utiliser un layout horizontal si l'écran est suffisamment large
            final useHorizontalLayout = constraints.maxWidth > 600;
            // Utiliser un layout compact pour les très petits écrans
            final useCompactLayout = constraints.maxWidth < 400;
            
            if (useHorizontalLayout) {
              // Layout horizontal : image à droite, infos à gauche
              return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  // Section des informations (gauche) - plus d'espace
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMenuInfo(context, menu, restaurant),
                    ),
                  ),
                  // Séparateur visuel
                  Container(
                    width: 1,
                    height: 200,
                    color: Colors.grey.shade200,
                  ),
                  // Image du menu (droite) - moins d'espace mais suffisant
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 200,
                      child: MenuImageWidget.createMenuCard(
              imageUrl: menu.imageUrl,
              width: double.infinity,
                        height: 200,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        fallbackIcon: Icons.restaurant_menu,
                        margin: const EdgeInsets.all(0),
                      ),
                    ),
                  ),
                ],
              );
            } else if (useCompactLayout) {
              // Layout compact pour très petits écrans
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du menu (haut) - hauteur réduite
                  MenuImageWidget.createMenuCard(
                    imageUrl: menu.imageUrl,
                    width: double.infinity,
                    height: 150, // Plus compact
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              fallbackIcon: Icons.restaurant_menu,
                    margin: const EdgeInsets.all(0),
                  ),
                  // Séparateur visuel
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  // Section des informations (bas) - padding réduit
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildCompactMenuInfo(context, menu, restaurant),
                  ),
                ],
              );
            } else {
              // Layout vertical standard : image au-dessus, infos en dessous
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du menu (haut)
                  MenuImageWidget.createMenuCard(
                    imageUrl: menu.imageUrl,
                    width: double.infinity,
                    height: 200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    fallbackIcon: Icons.restaurant_menu,
                    margin: const EdgeInsets.all(0),
                  ),
                  // Séparateur visuel
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  // Section des informations (bas)
          Padding(
            padding: const EdgeInsets.all(16),
                    child: _buildMenuInfo(context, menu, restaurant),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMenuInfo(BuildContext context, Menu menu, Restaurant? restaurant) {
    return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu.titre,
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
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    context.push('/admin/menu/edit/${menu.id}');
                  },
                  tooltip: 'Modifier le menu',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                IconButton(
                  icon: const Text('🗑️', style: TextStyle(fontSize: 20)),
                  onPressed: () => _showDeleteMenuDialog(menu),
                  tooltip: 'Supprimer le menu',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        menu.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
              ],
                    ),
                  ],
                ),
                if (restaurant != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            context.go('/restaurants/${restaurant.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.transparent,
                            ),
                            child: Text(
                              restaurant.nom,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.launch,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
                if (menu.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    menu.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 12),
        
        // Produits du menu
        Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                menu.produitsText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        if (menu.produits.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: menu.produits.map((produit) {
              final searchCriteria = ref.watch(searchCriteriaProvider);
              final isSelected = searchCriteria.produitsInclus.contains(produit);
              
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final currentCriteria = ref.read(searchCriteriaProvider);
                    final newProduitsInclus = List<String>.from(currentCriteria.produitsInclus);
                    if (isSelected) {
                      newProduitsInclus.remove(produit);
                    } else {
                      newProduitsInclus.add(produit);
                    }
                    _updateSearchCriteria(produitsInclus: newProduitsInclus);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade200 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.green.shade400 : Colors.green.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check : Icons.restaurant_menu,
                          size: 16,
                          color: isSelected ? Colors.green.shade700 : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          produit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.green.shade700 : Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 12),
        
        // Prix et disponibilité
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                menu.prixText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: menu.disponible ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                menu.disponible ? '✅ Disponible' : '❌ Indisponible',
                style: TextStyle(
                  fontSize: 12,
                  color: menu.disponible ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Allergènes
                Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        menu.allergenesText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                if (menu.allergenes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: menu.allergenes.map((allergene) {
                      final searchCriteria = ref.watch(searchCriteriaProvider);
                      final isSelected = searchCriteria.allergenesInclus.contains(allergene);
                      
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            final currentCriteria = ref.read(searchCriteriaProvider);
                            final newAllergenesInclus = List<String>.from(currentCriteria.allergenesInclus);
                            if (isSelected) {
                              newAllergenesInclus.remove(allergene);
                            } else {
                              newAllergenesInclus.add(allergene);
                            }
                            _updateSearchCriteria(allergenesInclus: newAllergenesInclus);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.shade200 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.orange.shade400 : Colors.orange.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? Icons.check : Icons.warning,
                                  size: 16,
                                  color: isSelected ? Colors.orange.shade700 : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  allergene,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.orange.shade700 : Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
    );
  }

  Widget _buildCompactMenuInfo(BuildContext context, Menu menu, Restaurant? restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                menu.titre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                menu.formattedDate,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
            ),
          ),
        ],
        ),
        if (restaurant != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.restaurant, size: 14, color: Colors.grey),
              const SizedBox(width: 2),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    context.go('/restaurants/${restaurant.id}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.transparent,
                    ),
                    child: Text(
                      restaurant.nom,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.launch,
                size: 10,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
        // Produits du menu (version compacte)
        if (menu.produits.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 3,
            children: menu.produits.take(3).map((produit) {
              final searchCriteria = ref.watch(searchCriteriaProvider);
              final isSelected = searchCriteria.produitsInclus.contains(produit);
              
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final currentCriteria = ref.read(searchCriteriaProvider);
                    final newProduitsInclus = List<String>.from(currentCriteria.produitsInclus);
                    if (isSelected) {
                      newProduitsInclus.remove(produit);
                    } else {
                      newProduitsInclus.add(produit);
                    }
                    _updateSearchCriteria(produitsInclus: newProduitsInclus);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade200 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green.shade400 : Colors.green.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check : Icons.restaurant_menu,
                          size: 12,
                          color: isSelected ? Colors.green.shade700 : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          produit,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.green.shade700 : Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (menu.produits.length > 3) ...[
            const SizedBox(height: 2),
            Text(
              '... et ${menu.produits.length - 3} autres',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
        if (menu.description != null) ...[
          const SizedBox(height: 8),
          Text(
            menu.description!,
            style: const TextStyle(fontSize: 14),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                menu.allergenesText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        if (menu.allergenes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 3,
            children: menu.allergenes.map((allergene) {
              final searchCriteria = ref.watch(searchCriteriaProvider);
              final isSelected = searchCriteria.allergenesInclus.contains(allergene);
              
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final currentCriteria = ref.read(searchCriteriaProvider);
                    final newAllergenesInclus = List<String>.from(currentCriteria.allergenesInclus);
                    if (isSelected) {
                      newAllergenesInclus.remove(allergene);
                    } else {
                      newAllergenesInclus.add(allergene);
                    }
                    _updateSearchCriteria(allergenesInclus: newAllergenesInclus);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade200 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.orange.shade400 : Colors.orange.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check : Icons.warning,
                          size: 12,
                          color: isSelected ? Colors.orange.shade700 : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          allergene,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.orange.shade700 : Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
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
                ref.invalidate(filteredMenusProvider);
                ref.invalidate(restaurantsProvider);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
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
              await _deleteMenuAndUpdate(menu);
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
      // Vérifier la validité du token avant de tenter la suppression
      final tokenValidator = TokenValidatorService();
      final isTokenValid = await tokenValidator.ensureTokenValid();
      
      if (!isTokenValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée. Veuillez vous reconnecter.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        // Redirection vers le profil en cas de problème d'authentification
        if (mounted) {
          context.push('/profil');
        }
        return;
      }

      final apiService = ApiService();
      final success = await apiService.deleteMenu(menu.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Rafraîchir la liste immédiatement
        if (mounted) {
          _refreshMenus();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la suppression';
      
      // Gérer les erreurs d'authentification spécifiquement
      if (e.toString().contains('Token expiré') || 
          e.toString().contains('Token d\'authentification manquant') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        errorMessage = 'Problème d\'authentification. Veuillez vous reconnecter.';
        if (mounted) {
          context.push('/profil');
        }
      } else {
        errorMessage = 'Erreur lors de la suppression: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }



  // Méthode pour rafraîchir manuellement la liste des menus
  void _refreshMenus() {
    // Incrémenter le provider de rafraîchissement
    ref.read(menuRefreshProvider.notifier).state++;
    
    // Invalider aussi les providers pour être sûr
    ref.invalidate(menusProvider);
    ref.invalidate(filteredMenusProvider);
    
    // Forcer la mise à jour de l'interface
    setState(() {});
  }

  // Méthode pour supprimer un menu et mettre à jour l'interface
  Future<void> _deleteMenuAndUpdate(Menu menu) async {
    try {
      // Vérifier la validité du token avant de tenter la suppression
      final tokenValidator = TokenValidatorService();
      final isTokenValid = await tokenValidator.ensureTokenValid();
      
      if (!isTokenValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée. Redirection vers le profil...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        if (mounted) {
          context.push('/profil');
        }
        return;
      }

      final apiService = ApiService();
      final success = await apiService.deleteMenu(menu.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Invalider les providers pour forcer le rechargement depuis l'API
        ref.invalidate(menusProvider);
        ref.invalidate(filteredMenusProvider);
        
        // Incrémenter le provider de rafraîchissement
        ref.read(menuRefreshProvider.notifier).state++;
        
        // Forcer la mise à jour de l'interface
        if (mounted) {
          setState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la suppression';
      
      // Gérer les erreurs d'authentification spécifiquement
      if (e.toString().contains('Token expiré') || 
          e.toString().contains('Token d\'authentification manquant') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        errorMessage = 'Problème d\'authentification. Veuillez vous reconnecter.';
        if (mounted) {
          context.push('/profil');
        }
      } else {
        errorMessage = 'Erreur lors de la suppression: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}