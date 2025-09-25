import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../models/menu.dart';
import '../services/api_service.dart';

/// Provider pour récupérer un restaurant par son ID
final restaurantByIdProvider = FutureProvider.family<Restaurant?, int>((ref, restaurantId) async {
  try {
    final apiService = ApiService();
    return await apiService.getRestaurant(restaurantId);
  } catch (e) {
    print('Erreur lors de la récupération du restaurant $restaurantId: $e');
    return null;
  }
});

/// Provider pour récupérer un menu par son ID
final menuByIdProvider = FutureProvider.family<Menu?, int>((ref, menuId) async {
  try {
    final apiService = ApiService();
    return await apiService.getMenu(menuId);
  } catch (e) {
    print('Erreur lors de la récupération du menu $menuId: $e');
    return null;
  }
});

/// Provider pour récupérer plusieurs restaurants par leurs IDs
final restaurantsByIdsProvider = FutureProvider.family<List<Restaurant>, List<int>>((ref, restaurantIds) async {
  try {
    final apiService = ApiService();
    final restaurants = <Restaurant>[];
    
    for (final id in restaurantIds) {
      try {
        final restaurant = await apiService.getRestaurant(id);
        restaurants.add(restaurant);
      } catch (e) {
        print('Erreur lors de la récupération du restaurant $id: $e');
      }
    }
    
    return restaurants;
  } catch (e) {
    print('Erreur lors de la récupération des restaurants: $e');
    return [];
  }
});

/// Provider pour récupérer plusieurs menus par leurs IDs
final menusByIdsProvider = FutureProvider.family<List<Menu>, List<int>>((ref, menuIds) async {
  try {
    final apiService = ApiService();
    final menus = <Menu>[];
    
    for (final id in menuIds) {
      try {
        final menu = await apiService.getMenu(id);
        menus.add(menu);
      } catch (e) {
        print('Erreur lors de la récupération du menu $id: $e');
      }
    }
    
    return menus;
  } catch (e) {
    print('Erreur lors de la récupération des menus: $e');
    return [];
  }
});
