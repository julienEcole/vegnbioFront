import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu.dart';
import '../models/search_criteria.dart';
import '../services/api_service.dart';
import '../services/menu_cache_service.dart';

// Provider pour forcer le rafraîchissement des menus
final menuRefreshProvider = StateProvider<int>((ref) => 0);

// Provider pour la liste des menus avec cache intelligent
final menusProvider = FutureProvider<List<Menu>>((ref) async {
  // Écouter le provider de rafraîchissement pour forcer la mise à jour
  final refreshCount = ref.watch(menuRefreshProvider);
  print('🔄 menusProvider appelé avec refreshCount: $refreshCount');
  
  // Utiliser le cache intelligent
  final cacheService = ref.read(menuCacheServiceProvider);
  final menus = await cacheService.getMenus();
  print('📋 menusProvider: Chargement depuis le cache intelligent (${menus.length} menus)');
  
  return menus;
});

// Provider pour un menu spécifique avec rafraîchissement automatique
final menuProvider = FutureProvider.family<Menu, int>((ref, id) async {
  // Écouter le provider de rafraîchissement pour forcer la mise à jour
  ref.watch(menuRefreshProvider);
  
  final apiService = ref.read(apiServiceProvider);
  return apiService.getMenu(id);
});

// Provider pour les menus d'un restaurant
final menusByRestaurantProvider = FutureProvider.family<List<Menu>, int>((ref, restaurantId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getMenusByRestaurant(restaurantId);
});

// ANCIEN PROVIDER SUPPRIMÉ - Le filtrage se fait maintenant en mémoire dans filteredMenusProvider

// Provider d'état pour les critères de recherche
final searchCriteriaProvider = StateProvider<MenuSearchCriteria>((ref) {
  return MenuSearchCriteria();
});

// Provider pour savoir si une recherche est active
final isSearchActiveProvider = Provider<bool>((ref) {
  final criteria = ref.read(searchCriteriaProvider);
  return !criteria.isEmpty;
});

// Provider pour les menus filtrés (filtrage en mémoire)
final filteredMenusProvider = FutureProvider<List<Menu>>((ref) async {
  final criteria = ref.watch(searchCriteriaProvider);
  final allMenus = await ref.watch(menusProvider.future);
  
  // Si aucun critère n'est défini, retourner tous les menus
  if (criteria.isEmpty) {
    return allMenus;
  }
  
  // Filtrer les menus en mémoire selon les critères
  return allMenus.where((menu) {
    // Filtre par titre
    if (criteria.titre != null && criteria.titre!.isNotEmpty) {
      if (!menu.titre.toLowerCase().contains(criteria.titre!.toLowerCase())) {
        return false;
      }
    }
    
    // Filtre par restaurant
    if (criteria.restaurantId != null) {
      if (menu.restaurantId != criteria.restaurantId) {
        return false;
      }
    }
    
    // Filtre par allergènes à exclure
    if (criteria.allergenesExclus.isNotEmpty) {
      // Le menu ne doit contenir AUCUN des allergènes à exclure
      for (final allergeneExclu in criteria.allergenesExclus) {
        if (menu.allergenes.contains(allergeneExclu)) {
          return false;
        }
      }
    }
    
    // Filtre par allergènes à inclure
    if (criteria.allergenesInclus.isNotEmpty) {
      // Le menu doit contenir TOUS les allergènes à inclure
      for (final allergeneInclus in criteria.allergenesInclus) {
        if (!menu.allergenes.contains(allergeneInclus)) {
          return false;
        }
      }
    }
    
    // Filtre par produits à exclure
    if (criteria.produitsExclus.isNotEmpty) {
      // Le menu ne doit contenir AUCUN des produits à exclure
      for (final produitExclu in criteria.produitsExclus) {
        if (menu.produits.contains(produitExclu)) {
          return false;
        }
      }
    }

    // Filtre par produits à inclure
    if (criteria.produitsInclus.isNotEmpty) {
      // Le menu doit contenir AU MOINS UN des produits à inclure
      bool hasMatchingProduct = false;
      for (final produitInclus in criteria.produitsInclus) {
        if (menu.produits.contains(produitInclus)) {
          hasMatchingProduct = true;
          break;
        }
      }
      if (!hasMatchingProduct) {
        return false;
      }
    }
    
    // Filtre par date
    if (criteria.dateDebut != null) {
      if (menu.date.isBefore(criteria.dateDebut!)) {
        return false;
      }
    }
    
    if (criteria.dateFin != null) {
      if (menu.date.isAfter(criteria.dateFin!)) {
        return false;
      }
    }

    // Filtre par disponibilité (seulement les menus disponibles)
    if (!menu.disponible) {
      return false;
    }
    
    return true;
  }).toList();
});

// Provider pour les allergènes disponibles dans la base de données
final availableAllergenesProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getAvailableAllergenes();
});

// Provider pour les allergènes filtrés par restaurant sélectionné (depuis la mémoire)
final availableAllergenesForRestaurantProvider = FutureProvider<List<String>>((ref) async {
  final searchCriteria = ref.watch(searchCriteriaProvider);
  final allMenus = await ref.watch(menusProvider.future);
  
  List<Menu> menusToCheck;
  
  // Si un restaurant est sélectionné, filtrer seulement ses menus
  if (searchCriteria.restaurantId != null) {
    menusToCheck = allMenus.where((menu) => menu.restaurantId == searchCriteria.restaurantId).toList();
    print('🏷️  Filtrage allergènes pour restaurant ${searchCriteria.restaurantId}');
  } else {
    // Sinon, utiliser tous les menus
    menusToCheck = allMenus;
    print('🏷️  Récupération de tous les allergènes disponibles');
  }
  
  // Extraire tous les allergènes uniques
  final Set<String> allergenes = {};
  for (final menu in menusToCheck) {
    allergenes.addAll(menu.allergenes);
  }
  
  final result = allergenes.toList()..sort();
  print('🏷️  Allergènes trouvés: $result (${result.length} au total)');
  return result;
});

// Provider pour les produits disponibles filtrés par restaurant sélectionné (depuis la mémoire)
final availableProduitsForRestaurantProvider = FutureProvider<List<String>>((ref) async {
  final searchCriteria = ref.watch(searchCriteriaProvider);
  final allMenus = await ref.watch(menusProvider.future);
  
  List<Menu> menusToCheck;
  
  // Si un restaurant est sélectionné, filtrer seulement ses menus
  if (searchCriteria.restaurantId != null) {
    menusToCheck = allMenus.where((menu) => menu.restaurantId == searchCriteria.restaurantId).toList();
    print('🍽️  Filtrage produits pour restaurant ${searchCriteria.restaurantId}');
  } else {
    // Sinon, utiliser tous les menus
    menusToCheck = allMenus;
    print('🍽️  Récupération de tous les produits disponibles');
  }
  
  // Debug: afficher les menus et leurs produits
  print('🍽️  Nombre de menus à analyser: ${menusToCheck.length}');
  for (final menu in menusToCheck.take(3)) { // Afficher seulement les 3 premiers pour éviter le spam
    print('🍽️  Menu "${menu.titre}": ${menu.produits.length} produits - ${menu.produits}');
  }
  
  // Extraire tous les produits uniques
  final Set<String> produits = {};
  for (final menu in menusToCheck) {
    if (menu.produits.isNotEmpty) {
      produits.addAll(menu.produits);
    }
  }
  
  final result = produits.toList()..sort();
  print('🍽️  Produits uniques trouvés: $result (${result.length} au total)');
  return result;
});

// Réexport du provider du service API depuis restaurant_provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});


