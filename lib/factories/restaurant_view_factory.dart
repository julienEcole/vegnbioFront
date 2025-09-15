import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simple_auth_provider.dart';
import '../screens/restaurant/restaurants_screen.dart';
import '../screens/restaurant/admin_restaurant_screen.dart';
import '../widgets/restaurant/public_restaurant_view.dart';

/// Factory pour gérer l'affichage des vues de restaurants
/// Responsabilité unique : déterminer quelle vue de restaurant afficher selon l'état d'auth et les permissions
class RestaurantViewFactory {
  
  /// Créer la vue de restaurant appropriée selon l'état d'authentification et les permissions
  static Widget createRestaurantView(WidgetRef ref, {int? restaurantId}) {
    print('🏪 [RestaurantViewFactory] createRestaurantView appelé');
    print('🏪 [RestaurantViewFactory] restaurantId: $restaurantId');
    
    final authState = ref.watch(simpleAuthProvider);
    print('🏪 [RestaurantViewFactory] AuthState: ${authState.status}, Role: ${authState.role}');
    
    // Si l'utilisateur est authentifié et a les permissions d'administration
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      print('🏪 [RestaurantViewFactory] Affichage: AdminRestaurantScreen');
      return const AdminRestaurantScreen();
    }
    
    // Sinon, afficher la vue publique
    print('🏪 [RestaurantViewFactory] Affichage: RestaurantsScreen (vue publique)');
    return const RestaurantsScreen();
  }
  
  /// Créer une vue de restaurant spécifique
  static Widget createSpecificRestaurantView(RestaurantViewType type, WidgetRef ref, {int? restaurantId}) {
    print('🏪 [RestaurantViewFactory] createSpecificRestaurantView: $type');
    
    switch (type) {
      case RestaurantViewType.publicList:
        return const RestaurantsScreen();
      case RestaurantViewType.adminList:
        return const AdminRestaurantScreen();
      case RestaurantViewType.publicWidget:
        return const PublicRestaurantView();
    }
  }
  
  /// Vérifier si l'utilisateur a les permissions d'administration pour les restaurants
  static bool _hasAdminPermissions(String? role) {
    if (role == null) return false;
    return ['admin', 'restaurateur'].contains(role.toLowerCase());
  }
  
  /// Obtenir le type de vue recommandé selon l'état d'authentification
  static RestaurantViewType getRecommendedViewType(WidgetRef ref) {
    final authState = ref.watch(simpleAuthProvider);
    
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      return RestaurantViewType.adminList;
    }
    
    return RestaurantViewType.publicList;
  }
  
  /// Vérifier si l'utilisateur peut gérer un restaurant spécifique
  static bool canManageRestaurant(WidgetRef ref, int restaurantId) {
    final authState = ref.watch(simpleAuthProvider);
    
    if (!authState.isAuthenticated) return false;
    
    final role = authState.role?.toLowerCase();
    
    // Les admins peuvent tout gérer
    if (role == 'admin') return true;
    
    // Les restaurateurs peuvent gérer leurs propres restaurants
    // TODO: Implémenter la vérification de propriété du restaurant
    if (role == 'restaurateur') {
      // Ici on devrait vérifier si le restaurateur possède ce restaurant
      return true; // Temporaire
    }
    
    return false;
  }
}

/// Types de vues de restaurants disponibles
enum RestaurantViewType {
  publicList,    // Liste publique des restaurants
  adminList,     // Interface d'administration des restaurants
  publicWidget,  // Widget public pour affichage dans d'autres écrans
}

/// Extensions pour faciliter l'utilisation
extension RestaurantViewTypeExtension on RestaurantViewType {
  String get displayName {
    switch (this) {
      case RestaurantViewType.publicList:
        return 'Liste des restaurants';
      case RestaurantViewType.adminList:
        return 'Administration des restaurants';
      case RestaurantViewType.publicWidget:
        return 'Widget restaurants';
    }
  }
  
  bool get requiresAuth {
    switch (this) {
      case RestaurantViewType.publicList:
      case RestaurantViewType.publicWidget:
        return false;
      case RestaurantViewType.adminList:
        return true;
    }
  }
  
  List<String> get requiredRoles {
    switch (this) {
      case RestaurantViewType.publicList:
      case RestaurantViewType.publicWidget:
        return [];
      case RestaurantViewType.adminList:
        return ['admin', 'restaurateur'];
    }
  }
}

