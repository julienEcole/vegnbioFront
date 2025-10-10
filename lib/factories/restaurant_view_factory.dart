import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/restaurant/restaurants_screen.dart';
import '../screens/restaurant/restaurant_form_screen.dart';
import '../screens/restaurant/restaurant_admin_dashboard.dart';
import '../widgets/restaurant/public_restaurant_view.dart';

/// Factory pour gérer l'affichage des vues de restaurants
/// Responsabilité unique : déterminer quelle vue de restaurant afficher selon l'état d'auth et les permissions
class RestaurantViewFactory {
  
  /// Créer la vue de restaurant appropriée selon l'état d'authentification et les permissions
  static Widget createRestaurantView(WidgetRef ref, {int? restaurantId}) {
    
    final authState = ref.watch(authProvider);

    // Si l'utilisateur est authentifié et a les permissions d'administration
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      return const RestaurantAdminDashboard();
    }
    
    // Sinon, afficher la vue publique
    return const RestaurantsScreen();
  }
  
  /// Créer une vue de restaurant spécifique
  static Widget createSpecificRestaurantView(RestaurantViewType type, WidgetRef ref, {int? restaurantId}) {

    switch (type) {
      case RestaurantViewType.publicList:
        return const RestaurantsScreen();
      case RestaurantViewType.adminList:
        return const RestaurantAdminDashboard();
      case RestaurantViewType.publicWidget:
        return const PublicRestaurantView();
      case RestaurantViewType.createForm:
        return const RestaurantFormScreen();
      case RestaurantViewType.editForm:
        return const RestaurantFormScreen(); // Utilise le même écran avec restaurantToEdit
    }
  }
  
  /// Vérifier si l'utilisateur a les permissions d'administration pour les restaurants
  static bool _hasAdminPermissions(String? role) {
    if (role == null) return false;
    return ['admin', 'restaurateur'].contains(role.toLowerCase());
  }
  
  /// Obtenir le type de vue recommandé selon l'état d'authentification
  static RestaurantViewType getRecommendedViewType(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      return RestaurantViewType.adminList;
    }
    
    return RestaurantViewType.publicList;
  }
  
  /// Obtenir le type de vue automatique selon le rôle de l'utilisateur
  static RestaurantViewType getAutoViewType(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return RestaurantViewType.publicList;
    }
    
    final role = authState.role?.toLowerCase();
    
    // Les utilisateurs avec permissions d'administration voient l'interface admin
    if (_hasAdminPermissions(role)) {
      return RestaurantViewType.adminList;
    }
    
    // Par défaut, vue publique
    return RestaurantViewType.publicList;
  }
  
  /// Vérifier si l'utilisateur peut gérer un restaurant spécifique
  static bool canManageRestaurant(WidgetRef ref, int restaurantId) {
    final authState = ref.watch(authProvider);
    
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
  createForm,    // Formulaire de création de restaurant
  editForm,      // Formulaire de modification de restaurant
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
      case RestaurantViewType.createForm:
        return 'Créer un restaurant';
      case RestaurantViewType.editForm:
        return 'Modifier le restaurant';
    }
  }
  
  bool get requiresAuth {
    switch (this) {
      case RestaurantViewType.publicList:
      case RestaurantViewType.publicWidget:
        return false;
      case RestaurantViewType.adminList:
      case RestaurantViewType.createForm:
      case RestaurantViewType.editForm:
        return true;
    }
  }
  
  List<String> get requiredRoles {
    switch (this) {
      case RestaurantViewType.publicList:
      case RestaurantViewType.publicWidget:
        return [];
      case RestaurantViewType.adminList:
      case RestaurantViewType.createForm:
      case RestaurantViewType.editForm:
        return ['admin', 'restaurateur'];
    }
  }
}

