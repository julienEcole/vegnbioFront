import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu.dart';
import '../models/restaurant.dart';
import '../models/search_criteria.dart';
import '../providers/menu_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/menu_image_widget.dart';
import '../widgets/navigation_bar.dart';
import '../services/navigation_service.dart';

/// Vue publique des menus accessible sans authentification
class PublicMenuView extends ConsumerStatefulWidget {
  const PublicMenuView({super.key});

  @override
  ConsumerState<PublicMenuView> createState() => _PublicMenuViewState();
}

class _PublicMenuViewState extends ConsumerState<PublicMenuView> {
  final TextEditingController _titreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Réinitialiser les filtres pour la vue publique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
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
    final menusAsync = ref.watch(filteredMenusProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Menus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton de connexion plus visible
          ElevatedButton.icon(
            onPressed: () async {
              final navigationService = NavigationService();
              await navigationService.navigateToLogin(context);
            },
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Bouton pour ouvrir les filtres
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
          // Message informatif
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
                        'Vue publique des menus',
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
          // Affichage des filtres actifs
          _buildActiveFiltersDisplay(),
          // Liste des menus
          Expanded(
            child: menusAsync.when(
              data: (menus) => restaurantsAsync.when(
                data: (restaurants) => _buildPublicMenusList(menus, restaurants),
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

  Widget _buildPublicMenusList(List<Menu> menus, List<Restaurant> restaurants) {
    if (menus.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun menu disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        final restaurant = restaurants.firstWhere(
          (r) => r.id == menu.restaurantId,
          orElse: () => Restaurant(id: 0, nom: 'Restaurant inconnu', quartier: 'Inconnu'),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du menu
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: MenuImageWidget.createMenuCard(
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
                ),
              ),
              // Informations du menu
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
                    if (restaurant.id > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.nom,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
                    if (menu.produits.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.list, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text(
                            'Produits :',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: menu.produits.map((produit) {
                          return Chip(
                            label: Text(
                              produit,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue.shade100,
                            avatar: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.blue,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Allergènes
                    if (menu.allergenes.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          const Text(
                            'Allergènes :',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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
      },
    );
  }

  Widget _buildActiveFiltersDisplay() {
    final searchCriteria = ref.watch(searchCriteriaProvider);
    
    // Si aucun filtre n'est actif, ne rien afficher
    if (searchCriteria.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  '🚫 $produit',
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
                  '🍽️ $produit',
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
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 12),
                const Text(
                  'Filtres de recherche',
                  style: TextStyle(
                    fontSize: 20,
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
                              labelText: '🏪 Restaurant',
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

  void _refreshMenus() {
    // Incrémenter le provider de rafraîchissement
    ref.read(menuRefreshProvider.notifier).state++;
    
    // Invalider aussi les providers pour être sûr
    ref.invalidate(menusProvider);
    ref.invalidate(filteredMenusProvider);
    
    // Forcer la mise à jour de l'interface
    setState(() {});
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
              ref.invalidate(menusProvider);
              ref.invalidate(restaurantsProvider);
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
