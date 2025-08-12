import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu.dart';
import '../models/search_criteria.dart';
import '../services/api_service.dart';

// Provider pour la liste des menus
final menusProvider = FutureProvider<List<Menu>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getMenus();
});

// Provider pour un menu spécifique
final menuProvider = FutureProvider.family<Menu, int>((ref, id) async {
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
  final criteria = ref.watch(searchCriteriaProvider);
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

// Réexport du provider du service API depuis restaurant_provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
