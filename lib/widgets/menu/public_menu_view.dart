import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/menu.dart';
import '../../models/restaurant.dart';
import '../../models/search_criteria.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_widgets.dart';
import 'menu_image_widget.dart';

/// Provider pour sauvegarder les filtres avant la redirection vers la connexion
final savedFiltersProvider = StateProvider<MenuSearchCriteria?>((ref) => null);

/// Vue publique des menus accessible sans authentification
class PublicMenuView extends ConsumerStatefulWidget {
  final int? restaurantId;
  
  const PublicMenuView({super.key, this.restaurantId});

  @override
  ConsumerState<PublicMenuView> createState() => _PublicMenuViewState();
}

class _PublicMenuViewState extends ConsumerState<PublicMenuView> {
  final TextEditingController _titreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Vérifier s'il y a des filtres sauvegardés à restaurer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedFilters = ref.read(savedFiltersProvider);
      if (savedFilters != null) {
        // Restaurer les filtres sauvegardés
        ref.read(searchCriteriaProvider.notifier).state = savedFilters;
        // Effacer les filtres sauvegardés
        ref.read(savedFiltersProvider.notifier).state = null;
        print('🔄 [PublicMenuView] Filtres restaurés après connexion');
      } else {
        // Réinitialiser les filtres pour la vue publique
        ref.read(searchCriteriaProvider.notifier).state = MenuSearchCriteria();
      }
      _syncControllersWithFilters();
    });
  }

  /// Synchroniser les contrôleurs avec les filtres actuels
  void _syncControllersWithFilters() {
    final currentSearchCriteria = ref.read(searchCriteriaProvider);
    _titreController.text = currentSearchCriteria.titre ?? '';
  }

  /// Gérer la connexion avec sauvegarde des filtres
  void _handleLoginWithFilters() {
    final currentFilters = ref.read(searchCriteriaProvider);
    
    // Sauvegarder les filtres actuels
    ref.read(savedFiltersProvider.notifier).state = currentFilters;
    
    print('💾 [PublicMenuView] Filtres sauvegardés avant connexion: $currentFilters');
    
    // Rediriger vers l'écran de connexion
    context.go('/profil?view=login');
  }

  /// Gérer la déconnexion
  void _handleLogout() {
    ref.read(authProvider.notifier).logout();
    print('🚪 [PublicMenuView] Déconnexion effectuée');
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🌐 [PublicMenuView] ===== DÉBUT build() =====');
    debugPrint('🌐 [PublicMenuView] ===== DÉBUT build() =====');
    
    final menusAsync = ref.watch(filteredMenusProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Menus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton de connexion/déconnexion dynamique
          ElevatedButton.icon(
            onPressed: authState.isAuthenticated ? _handleLogout : _handleLoginWithFilters,
            icon: Icon(authState.isAuthenticated ? Icons.logout : Icons.login),
            label: Text(authState.isAuthenticated ? 'Se déconnecter' : 'Se connecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: authState.isAuthenticated ? Colors.red : Colors.green,
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
      body: Stack(
        children: [
          Column(
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
          // Bouton flottant du panier
          const CartFloatingButton(),
        ],
      ),
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
                              color: const Color(0xFF387D35),
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
                    // Prix du menu
                    Row(
                      children: [
                        const Icon(Icons.euro, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          menu.prixText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF387D35),
                          ),
                        ),
                      ],
                    ),
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
                    // Bouton d'ajout au panier (seulement si connecté)
                    const SizedBox(height: 16),
                    _buildAddToCartButton(menu, restaurant.id),
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
    final currentSearchCriteria = ref.watch(searchCriteriaProvider);
    
    // Si aucun filtre n'est actif, ne rien afficher
    if (currentSearchCriteria.isEmpty) {
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
                  color: const Color(0xFF387D35),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showFiltersModal(context),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF387D35),
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
              if (currentSearchCriteria.titre != null && currentSearchCriteria.titre!.isNotEmpty)
                _buildFilterChip(
                  'Titre: ${currentSearchCriteria.titre}',
                  Colors.blue.shade100,
                  () => _updateSearchCriteria(titre: ''),
                ),
              
              // Filtre par restaurant
              if (currentSearchCriteria.restaurantId != null)
                _buildFilterChip(
                  'Restaurant sélectionné',
                  Colors.green.shade100,
                  () => _updateSearchCriteria(restaurantId: null),
                ),
              
              // Allergènes exclus
              ...currentSearchCriteria.allergenesExclus.map((allergene) => 
                _buildFilterChip(
                  'Exclure: $allergene',
                  Colors.red.shade100,
                  () => _updateSearchCriteria(
                    allergenesExclus: currentSearchCriteria.allergenesExclus
                        .where((a) => a != allergene)
                        .toList(),
                  ),
                ),
              ),
              
              // Allergènes inclus
              ...currentSearchCriteria.allergenesInclus.map((allergene) => 
                _buildFilterChip(
                  'Inclure: $allergene',
                  Colors.green.shade100,
                  () => _updateSearchCriteria(
                    allergenesInclus: currentSearchCriteria.allergenesInclus
                        .where((a) => a != allergene)
                        .toList(),
                  ),
                ),
              ),
              
              // Produits exclus
              ...currentSearchCriteria.produitsExclus.map((produit) => 
                _buildFilterChip(
                  '🚫 $produit',
                  Colors.red.shade100,
                  () => _updateSearchCriteria(
                    produitsExclus: currentSearchCriteria.produitsExclus
                        .where((p) => p != produit)
                        .toList(),
                  ),
                ),
              ),
              
              // Produits inclus
              ...currentSearchCriteria.produitsInclus.map((produit) => 
                _buildFilterChip(
                  '🍽️ $produit',
                  Colors.green.shade100,
                  () => _updateSearchCriteria(
                    produitsInclus: currentSearchCriteria.produitsInclus
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

// Remplacez la méthode _buildFiltersModal() par celle-ci :

  Widget _buildFiltersModal() {
    final currentSearchCriteria = ref.watch(searchCriteriaProvider);
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
        mainAxisSize: MainAxisSize.min, // AJOUT IMPORTANT
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

          // Contenu du formulaire avec contraintes fixes
          Expanded(
            child: ListView( // Remplacé SingleChildScrollView par ListView
              padding: const EdgeInsets.all(16),
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
                          value: currentSearchCriteria.restaurantId,
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
                              titre: currentSearchCriteria.titre,
                              restaurantId: value,
                            );
                          },
                        ),
                        loading: () => const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Section Allergènes
                _buildAllergenesSection(),

                const SizedBox(height: 20),

                // Section Produits
                _buildProduitsSection(),

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
        ],
      ),
    );
  }

  Widget _buildAllergenesSection() {
    final menusAsync = ref.watch(menusProvider);
    
    return menusAsync.when(
      data: (menus) {
        // Extraire les allergènes directement des menus
        final Set<String> allergenesSet = {};
        for (final menu in menus) {
          allergenesSet.addAll(menu.allergenes);
        }
        final allergenes = allergenesSet.toList()..sort();
        
        return _buildAllergenesContentDirect(allergenes);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Erreur lors du chargement des allergènes: $error'),
        ),
      ),
    );
  }

  Widget _buildAllergenesContentDirect(List<String> allergenes) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Allergènes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exclure les menus contenant ces allergènes :',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: allergenes.map((allergene) {
                // Re-lire les critères à chaque reconstruction pour avoir l'état actuel
                final currentCriteria = ref.watch(searchCriteriaProvider);
                final isExcluded = currentCriteria.allergenesExclus.contains(allergene);
                final isIncluded = currentCriteria.allergenesInclus.contains(allergene);
                
                // Debug: afficher l'état des filtres
                print('🔍 [FilterDebug] Allergène: $allergene');
                print('🔍 [FilterDebug] isExcluded: $isExcluded');
                print('🔍 [FilterDebug] isIncluded: $isIncluded');
                print('🔍 [FilterDebug] allergenesExclus: ${currentCriteria.allergenesExclus}');
                print('🔍 [FilterDebug] allergenesInclus: ${currentCriteria.allergenesInclus}');
            
            return FilterChip(
              label: Text(allergene),
              selected: isExcluded || isIncluded,
              onSelected: (selected) {
                // Re-lire les critères actuels pour avoir les valeurs les plus récentes
                final currentCriteria = ref.read(searchCriteriaProvider);
                final isCurrentlyExcluded = currentCriteria.allergenesExclus.contains(allergene);
                final isCurrentlyIncluded = currentCriteria.allergenesInclus.contains(allergene);
                
                if (isCurrentlyExcluded) {
                  // Retirer de la liste d'exclusion
                  _updateSearchCriteria(
                    allergenesExclus: currentCriteria.allergenesExclus
                        .where((a) => a != allergene)
                        .toList(),
                  );
                } else if (isCurrentlyIncluded) {
                  // Retirer de la liste d'inclusion
                  _updateSearchCriteria(
                    allergenesInclus: currentCriteria.allergenesInclus
                        .where((a) => a != allergene)
                        .toList(),
                  );
                } else {
                  // Ajouter à la liste d'exclusion par défaut
                  _updateSearchCriteria(
                    allergenesExclus: [...currentCriteria.allergenesExclus, allergene],
                  );
                }
              },
              backgroundColor: isExcluded 
                  ? Colors.red.shade100 
                  : isIncluded 
                      ? Colors.green.shade100 
                      : Colors.grey.shade100,
              selectedColor: isExcluded ? Colors.red.shade200 : Colors.green.shade200,
              checkmarkColor: isExcluded ? Colors.red.shade700 : Colors.green.shade700,
              avatar: Icon(
                isExcluded 
                    ? Icons.block 
                    : isIncluded 
                        ? Icons.check 
                        : Icons.warning,
                size: 16,
                color: isExcluded 
                    ? Colors.red.shade700 
                    : isIncluded 
                        ? Colors.green.shade700 
                        : Colors.grey.shade600,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Inclure seulement les menus contenant ces allergènes :',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: allergenes.map((allergene) {
            final currentCriteria = ref.watch(searchCriteriaProvider);
            final isIncluded = currentCriteria.allergenesInclus.contains(allergene);
            final isExcluded = currentCriteria.allergenesExclus.contains(allergene);
            
            return FilterChip(
              label: Text(allergene),
              selected: isIncluded,
              onSelected: (selected) {
                if (isIncluded) {
                  // Retirer de la liste d'inclusion
                  _updateSearchCriteria(
                    allergenesInclus: currentCriteria.allergenesInclus
                        .where((a) => a != allergene)
                        .toList(),
                  );
                } else if (isExcluded) {
                  // Retirer de l'exclusion et ajouter à l'inclusion
                  _updateSearchCriteria(
                    allergenesExclus: currentCriteria.allergenesExclus
                        .where((a) => a != allergene)
                        .toList(),
                    allergenesInclus: [...currentCriteria.allergenesInclus, allergene],
                  );
                } else {
                  // Ajouter à la liste d'inclusion
                  _updateSearchCriteria(
                    allergenesInclus: [...currentCriteria.allergenesInclus, allergene],
                  );
                }
              },
              backgroundColor: isIncluded 
                  ? Colors.green.shade100 
                  : Colors.grey.shade100,
              selectedColor: Colors.green.shade200,
              checkmarkColor: Colors.green.shade700,
              avatar: Icon(
                isIncluded ? Icons.check : Icons.add,
                size: 16,
                color: isIncluded 
                    ? Colors.green.shade700 
                    : Colors.grey.shade600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProduitsSection() {
    final menusAsync = ref.watch(menusProvider);
    
    return menusAsync.when(
      data: (menus) {
        // Extraire les produits directement des menus
        final Set<String> produitsSet = {};
        for (final menu in menus) {
          produitsSet.addAll(menu.produits);
        }
        final produits = produitsSet.toList()..sort();
        
        return _buildProduitsContentDirect(produits);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Erreur lors du chargement des produits: $error'),
        ),
      ),
    );
  }

  Widget _buildProduitsContentDirect(List<String> produits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🍽️ Produits',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Exclure les menus contenant ces produits :',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: produits.map((produit) {
            // Re-lire les critères à chaque reconstruction pour avoir l'état actuel
            final currentCriteria = ref.watch(searchCriteriaProvider);
            final isExcluded = currentCriteria.produitsExclus.contains(produit);
            final isIncluded = currentCriteria.produitsInclus.contains(produit);
            
            // Debug: afficher l'état des filtres pour les produits
            print('🔍 [FilterDebug] Produit: $produit');
            print('🔍 [FilterDebug] isExcluded: $isExcluded');
            print('🔍 [FilterDebug] isIncluded: $isIncluded');
            print('🔍 [FilterDebug] produitsExclus: ${currentCriteria.produitsExclus}');
            print('🔍 [FilterDebug] produitsInclus: ${currentCriteria.produitsInclus}');
            
            return FilterChip(
              label: Text(produit),
              selected: isExcluded || isIncluded,
              onSelected: (selected) {
                // Re-lire les critères actuels pour avoir les valeurs les plus récentes
                final currentCriteria = ref.read(searchCriteriaProvider);
                final isCurrentlyExcluded = currentCriteria.produitsExclus.contains(produit);
                final isCurrentlyIncluded = currentCriteria.produitsInclus.contains(produit);
                
                if (isCurrentlyExcluded) {
                  // Retirer de la liste d'exclusion
                  _updateSearchCriteria(
                    produitsExclus: currentCriteria.produitsExclus
                        .where((p) => p != produit)
                        .toList(),
                  );
                } else if (isCurrentlyIncluded) {
                  // Retirer de la liste d'inclusion
                  _updateSearchCriteria(
                    produitsInclus: currentCriteria.produitsInclus
                        .where((p) => p != produit)
                        .toList(),
                  );
                } else {
                  // Ajouter à la liste d'exclusion par défaut
                  _updateSearchCriteria(
                    produitsExclus: [...currentCriteria.produitsExclus, produit],
                  );
                }
              },
              backgroundColor: isExcluded 
                  ? Colors.red.shade100 
                  : isIncluded 
                      ? Colors.green.shade100 
                      : Colors.grey.shade100,
              selectedColor: isExcluded ? Colors.red.shade200 : Colors.green.shade200,
              checkmarkColor: isExcluded ? Colors.red.shade700 : Colors.green.shade700,
              avatar: Icon(
                isExcluded 
                    ? Icons.block 
                    : isIncluded 
                        ? Icons.check 
                        : Icons.restaurant_menu,
                size: 16,
                color: isExcluded 
                    ? Colors.red.shade700 
                    : isIncluded 
                        ? Colors.green.shade700 
                        : Colors.grey.shade600,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Inclure seulement les menus contenant ces produits :',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: produits.map((produit) {
            final currentCriteria = ref.watch(searchCriteriaProvider);
            final isIncluded = currentCriteria.produitsInclus.contains(produit);
            final isExcluded = currentCriteria.produitsExclus.contains(produit);
            
            return FilterChip(
              label: Text(produit),
              selected: isIncluded,
              onSelected: (selected) {
                if (isIncluded) {
                  // Retirer de la liste d'inclusion
                  _updateSearchCriteria(
                    produitsInclus: currentCriteria.produitsInclus
                        .where((p) => p != produit)
                        .toList(),
                  );
                } else if (isExcluded) {
                  // Retirer de l'exclusion et ajouter à l'inclusion
                  _updateSearchCriteria(
                    produitsExclus: currentCriteria.produitsExclus
                        .where((p) => p != produit)
                        .toList(),
                    produitsInclus: [...currentCriteria.produitsInclus, produit],
                  );
                } else {
                  // Ajouter à la liste d'inclusion
                  _updateSearchCriteria(
                    produitsInclus: [...currentCriteria.produitsInclus, produit],
                  );
                }
              },
              backgroundColor: isIncluded 
                  ? Colors.green.shade100 
                  : Colors.grey.shade100,
              selectedColor: Colors.green.shade200,
              checkmarkColor: Colors.green.shade700,
              avatar: Icon(
                isIncluded ? Icons.check : Icons.add,
                size: 16,
                color: isIncluded 
                    ? Colors.green.shade700 
                    : Colors.grey.shade600,
              ),
            );
          }).toList(),
        ),
      ],
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
      titre: titre,
      restaurantId: restaurantId,
      allergenesExclus: allergenesExclus,
      allergenesInclus: allergenesInclus,
      produitsExclus: produitsExclus,
      produitsInclus: produitsInclus,
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

  /// Construire le bouton d'ajout au panier
  Widget _buildAddToCartButton(Menu menu, int restaurantId) {
    final authState = ref.watch(authProvider);
    
    // Si l'utilisateur n'est pas connecté, afficher un bouton pour se connecter
    if (!authState.isAuthenticated) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // Sauvegarder les filtres actuels avant la redirection
            final currentFilters = ref.read(searchCriteriaProvider);
            ref.read(savedFiltersProvider.notifier).state = currentFilters;
            
            // Rediriger vers la connexion
            context.go('/profil?view=login');
          },
          icon: const Icon(Icons.login),
          label: const Text('Se connecter pour commander'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    // Si l'utilisateur est connecté, afficher le bouton d'ajout au panier
    final cartNotifier = ref.read(cartProvider.notifier);
    final hasItem = cartNotifier.hasItem(menu, restaurantId);
    final itemQuantity = cartNotifier.getItemQuantity(menu, restaurantId);

    return Row(
      children: [
        // Bouton de diminution (si l'item est dans le panier)
        if (hasItem) ...[
          IconButton(
            onPressed: () {
              cartNotifier.updateItemQuantity(menu, restaurantId, itemQuantity - 1);
            },
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        // Bouton principal d'ajout au panier
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (hasItem) {
                // Si l'item est déjà dans le panier, augmenter la quantité
                cartNotifier.updateItemQuantity(menu, restaurantId, itemQuantity + 1);
                
                // Afficher un message de confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quantité mise à jour: ${itemQuantity + 1}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                // Ajouter l'item au panier
                cartNotifier.addItem(menu, restaurantId);
                
                // Vérifier s'il y a une erreur
                final cartState = ref.read(cartProvider);
                if (cartState.error != null) {
                  // Afficher le message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cartState.error!),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  // Afficher un message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${menu.titre} ajouté au panier'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: Icon(hasItem ? Icons.add_shopping_cart : Icons.shopping_cart),
            label: Text(
              hasItem 
                ? 'Quantité: $itemQuantity'
                : 'Ajouter au panier',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasItem 
                ? Colors.orange 
                : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Bouton d'augmentation (si l'item est dans le panier)
        if (hasItem) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              cartNotifier.updateItemQuantity(menu, restaurantId, itemQuantity + 1);
            },
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
