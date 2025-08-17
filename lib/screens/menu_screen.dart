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

class MenuScreen extends ConsumerStatefulWidget {
  final int? restaurantId;
  
  const MenuScreen({super.key, this.restaurantId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final TextEditingController _titreController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    // Si un restaurantId est fourni, initialiser le filtre de recherche
    if (widget.restaurantId != null) {
      // Utiliser addPostFrameCallback pour s'assurer que le widget est monté
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentCriteria = ref.read(searchCriteriaProvider);
        ref.read(searchCriteriaProvider.notifier).state = currentCriteria.copyWith(
          restaurantId: widget.restaurantId,
        );
        setState(() {
          _isSearching = true; // Afficher automatiquement la section de recherche
        });
      });
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menusAsync = ref.watch(filteredMenusProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);

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
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _titreController.clear();
                  ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) _buildSearchSection(),
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

  Widget _buildSearchSection() {
    final searchCriteria = ref.watch(searchCriteriaProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherche par titre
          TextField(
            controller: _titreController,
            decoration: const InputDecoration(
              labelText: 'Rechercher par titre',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _updateSearchCriteria(titre: value),
          ),
          const SizedBox(height: 12),
          
          // Sélection de restaurant
          restaurantsAsync.when(
            data: (restaurants) => DropdownButtonFormField<int>(
              value: searchCriteria.restaurantId,
              decoration: const InputDecoration(
                labelText: 'Filtrer par restaurant',
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
                // Réinitialiser les filtres d'allergènes quand on change de restaurant
                ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria(
                  titre: searchCriteria.titre,
                  restaurantId: value,
                  // Les allergènes sont réinitialisés (listes vides)
                );
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),
          
          // Allergènes à exclure
          const Text('Exclure les allergènes :', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final availableAllergenesAsync = ref.watch(availableAllergenesForRestaurantProvider);
              
              return availableAllergenesAsync.when(
                data: (availableAllergenes) {
                  if (availableAllergenes.isEmpty) {
                    final searchCriteria = ref.watch(searchCriteriaProvider);
                    final messageText = searchCriteria.restaurantId != null 
                        ? 'Aucun allergène trouvé pour ce restaurant'
                        : 'Aucun allergène trouvé dans les menus';
                    return Text(messageText, style: const TextStyle(color: Colors.grey));
                  }
                  
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
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
                loading: () => const SizedBox(
                  height: 32,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text(
                  'Erreur de chargement des allergènes: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          // Allergènes à inclure
          const Text('Doit contenir les allergènes :', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final availableAllergenesAsync = ref.watch(availableAllergenesForRestaurantProvider);
              
              return availableAllergenesAsync.when(
                data: (availableAllergenes) {
                  if (availableAllergenes.isEmpty) {
                    final searchCriteria = ref.watch(searchCriteriaProvider);
                    final messageText = searchCriteria.restaurantId != null 
                        ? 'Aucun allergène trouvé pour ce restaurant'
                        : 'Aucun allergène trouvé dans les menus';
                    return Text(messageText, style: const TextStyle(color: Colors.grey));
                  }
                  
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
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
                loading: () => const SizedBox(
                  height: 32,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text(
                  'Erreur de chargement des allergènes: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          // Boutons d'action
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _titreController.clear();
                  ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
                },
                child: const Text('Effacer les filtres'),
              ),
              const SizedBox(width: 12),
              Text(
                '${searchCriteria.allergenesExclus.length} exclus, ${searchCriteria.allergenesInclus.length} inclus',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
  }) {
    final currentCriteria = ref.read(searchCriteriaProvider);
    
    ref.read(searchCriteriaProvider.notifier).state = currentCriteria.copyWith(
      titre: titre ?? (titre == '' ? null : currentCriteria.titre),
      restaurantId: restaurantId ?? currentCriteria.restaurantId,
      allergenesExclus: allergenesExclus ?? currentCriteria.allergenesExclus,
      allergenesInclus: allergenesInclus ?? currentCriteria.allergenesInclus,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du menu
          MenuImageWidget(
            imageUrl: menu.imageUrl,
            width: double.infinity,
            height: 180,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            fallbackIcon: Icons.restaurant_menu,
            margin: const EdgeInsets.all(0),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                      return Chip(
                        label: Text(
                          allergene,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.orange.shade100,
                        avatar: const Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
}