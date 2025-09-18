import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_view_factory.dart';
import 'menu_view_factory.dart';
import 'restaurant_view_factory.dart';
import 'event_view_factory.dart';
import 'service_view_factory.dart';
import 'dashboard_view_factory.dart';
import '../providers/auth_provider.dart';

/// Factory principale qui orchestre toutes les autres factories
/// Responsabilité unique : router vers la bonne factory selon le type de vue demandé
class ViewFactory {
  
  /// Créer une vue selon son type et ses paramètres
  static Widget createView(ViewType type, WidgetRef ref, {Map<String, dynamic>? params}) {
    print('🏭 [ViewFactory] createView appelé pour: $type');
    print('🏭 [ViewFactory] Paramètres: $params');
    
    switch (type) {
      case ViewType.auth:
        return _createAuthView(ref, params);
      case ViewType.menu:
        return _createMenuView(ref, params);
      case ViewType.restaurant:
        return _createRestaurantView(ref, params);
      case ViewType.event:
        return _createEventView(ref, params);
      case ViewType.service:
        return _createServiceView(ref, params);
      case ViewType.dashboard:
        return _createDashboardView(ref, params);
    }
  }
  
  /// Obtenir la factory appropriée selon le type de vue
  static dynamic getFactory(ViewType type) {
    switch (type) {
      case ViewType.auth:
        return AuthViewFactory;
      case ViewType.menu:
        return MenuViewFactory;
      case ViewType.restaurant:
        return RestaurantViewFactory;
      case ViewType.event:
        return EventViewFactory;
      case ViewType.service:
        return ServiceViewFactory;
      case ViewType.dashboard:
        return DashboardViewFactory;
    }
  }
  
  /// Vérifier si l'utilisateur a accès à un type de vue
  static bool canAccessView(ViewType type, WidgetRef ref, {Map<String, dynamic>? params}) {
    switch (type) {
      case ViewType.auth:
        return true; // L'authentification est accessible à tous
      case ViewType.menu:
        final menuType = _getMenuViewType(params);
        return menuType.requiresAuth ? _checkAuthForView(ref, menuType.requiredRoles) : true;
      case ViewType.restaurant:
        final restaurantType = _getRestaurantViewType(params);
        return restaurantType.requiresAuth ? _checkAuthForView(ref, restaurantType.requiredRoles) : true;
      case ViewType.event:
        final eventType = _getEventViewType(params);
        return eventType.requiresAuth ? _checkAuthForView(ref, eventType.requiredRoles) : true;
      case ViewType.service:
        final serviceType = _getServiceViewType(params);
        return serviceType.requiresAuth ? _checkAuthForView(ref, serviceType.requiredRoles) : true;
      case ViewType.dashboard:
        final dashboardType = _getDashboardViewType(params);
        return DashboardViewFactory.canAccessDashboard(ref, dashboardType);
    }
  }
  
  // Méthodes privées pour créer les vues spécifiques
  
  static Widget _createAuthView(WidgetRef ref, Map<String, dynamic>? params) {
    final authType = params?['authType'] as AuthViewType?;
    return AuthViewFactory.createAuthView(ref, forcedType: authType);
  }
  
  static Widget _createMenuView(WidgetRef ref, Map<String, dynamic>? params) {
    final menuType = _getMenuViewType(params);
    final restaurantId = params?['restaurantId'] as int?;
    final menuId = params?['menuId'] as int?;
    
    // Si aucun type spécifique n'est demandé, utiliser la logique automatique
    final effectiveMenuType = menuType == MenuViewType.publicList && params == null 
        ? MenuViewFactory.getAutoViewType(ref)
        : menuType;
    
    return MenuViewFactory.createSpecificMenuView(effectiveMenuType, ref, 
        restaurantId: restaurantId, menuId: menuId);
  }
  
  static Widget _createRestaurantView(WidgetRef ref, Map<String, dynamic>? params) {
    final restaurantType = _getRestaurantViewType(params);
    final restaurantId = params?['restaurantId'] as int?;
    
    // Si aucun type spécifique n'est demandé, utiliser la logique automatique
    final effectiveRestaurantType = restaurantType == RestaurantViewType.publicList && params == null 
        ? RestaurantViewFactory.getAutoViewType(ref)
        : restaurantType;
    
    return RestaurantViewFactory.createSpecificRestaurantView(effectiveRestaurantType, ref, 
        restaurantId: restaurantId);
  }
  
  static Widget _createEventView(WidgetRef ref, Map<String, dynamic>? params) {
    final eventType = _getEventViewType(params);
    final eventId = params?['eventId'] as int?;
    
    return EventViewFactory.createSpecificEventView(eventType, ref, eventId: eventId);
  }
  
  static Widget _createServiceView(WidgetRef ref, Map<String, dynamic>? params) {
    final serviceType = _getServiceViewType(params);
    final serviceId = params?['serviceId'] as int?;
    
    return ServiceViewFactory.createSpecificServiceView(serviceType, ref, serviceId: serviceId);
  }
  
  static Widget _createDashboardView(WidgetRef ref, Map<String, dynamic>? params) {
    final dashboardType = _getDashboardViewType(params);
    return DashboardViewFactory.createSpecificDashboardView(dashboardType, ref);
  }
  
  // Méthodes utilitaires pour extraire les types depuis les paramètres
  
  static MenuViewType _getMenuViewType(Map<String, dynamic>? params) {
    return params?['menuViewType'] as MenuViewType? ?? MenuViewType.publicList;
  }
  
  static RestaurantViewType _getRestaurantViewType(Map<String, dynamic>? params) {
    return params?['restaurantViewType'] as RestaurantViewType? ?? RestaurantViewType.publicList;
  }
  
  static EventViewType _getEventViewType(Map<String, dynamic>? params) {
    return params?['eventViewType'] as EventViewType? ?? EventViewType.publicList;
  }
  
  static ServiceViewType _getServiceViewType(Map<String, dynamic>? params) {
    return params?['serviceViewType'] as ServiceViewType? ?? ServiceViewType.publicList;
  }
  
  static DashboardViewType _getDashboardViewType(Map<String, dynamic>? params) {
    return params?['dashboardViewType'] as DashboardViewType? ?? DashboardViewType.defaultView;
  }
  
  static bool _checkAuthForView(WidgetRef ref, List<String> requiredRoles) {
    // Si aucun rôle n'est requis, autoriser l'accès
    if (requiredRoles.isEmpty) return true;
    
    // Vérifier l'authentification
    final authState = ref.read(authProvider);
    
    if (!authState.isAuthenticated) {
      print('🚫 [ViewFactory] Accès refusé: utilisateur non authentifié');
      return false;
    }
    
    final userRole = authState.role?.toLowerCase();
    if (userRole == null) {
      print('🚫 [ViewFactory] Accès refusé: rôle utilisateur non défini');
      return false;
    }
    
    final hasPermission = requiredRoles.any((role) => role.toLowerCase() == userRole);
    
    if (hasPermission) {
      print('✅ [ViewFactory] Accès autorisé pour le rôle: $userRole');
    } else {
      print('🚫 [ViewFactory] Accès refusé: rôle $userRole non autorisé (requis: $requiredRoles)');
    }
    
    return hasPermission;
  }
}

/// Types de vues principales disponibles dans l'application
enum ViewType {
  auth,        // Vues d'authentification
  menu,        // Vues de menus
  restaurant,  // Vues de restaurants
  event,       // Vues d'événements
  service,     // Vues de services
  dashboard,   // Vues de tableaux de bord
}

/// Extensions pour faciliter l'utilisation
extension ViewTypeExtension on ViewType {
  String get displayName {
    switch (this) {
      case ViewType.auth:
        return 'Authentification';
      case ViewType.menu:
        return 'Menus';
      case ViewType.restaurant:
        return 'Restaurants';
      case ViewType.event:
        return 'Événements';
      case ViewType.service:
        return 'Services';
      case ViewType.dashboard:
        return 'Tableau de bord';
    }
  }
  
  String get routePath {
    switch (this) {
      case ViewType.auth:
        return '/profil';
      case ViewType.menu:
        return '/menus';
      case ViewType.restaurant:
        return '/restaurants';
      case ViewType.event:
        return '/evenements';
      case ViewType.service:
        return '/services';
      case ViewType.dashboard:
        return '/dashboard';
    }
  }
}

