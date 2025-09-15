import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simple_auth_provider.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/menu/admin_menu_screen.dart';
import '../widgets/menu/public_menu_view.dart';

/// Factory pour gérer l'affichage des vues de menus
/// Responsabilité unique : déterminer quelle vue de menu afficher selon l'état d'auth et les permissions
class MenuViewFactory {
  
  /// Créer la vue de menu appropriée selon l'état d'authentification et les permissions
  static Widget createMenuView(WidgetRef ref, {int? restaurantId}) {
    print('🍽️ [MenuViewFactory] createMenuView appelé');
    print('🍽️ [MenuViewFactory] restaurantId: $restaurantId');
    
    final authState = ref.watch(simpleAuthProvider);
    print('🍽️ [MenuViewFactory] AuthState: ${authState.status}, Role: ${authState.role}');
    
    // Si l'utilisateur est authentifié et a les permissions d'administration
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      print('🍽️ [MenuViewFactory] Affichage: AdminMenuScreen');
      return const AdminMenuScreen();
    }
    
    // Sinon, afficher la vue publique
    print('🍽️ [MenuViewFactory] Affichage: MenuScreen (vue publique)');
    return MenuScreen(restaurantId: restaurantId);
  }
  
  /// Créer une vue de menu spécifique
  static Widget createSpecificMenuView(MenuViewType type, WidgetRef ref, {int? restaurantId, int? menuId}) {
    print('🍽️ [MenuViewFactory] createSpecificMenuView: $type');
    
    switch (type) {
      case MenuViewType.publicList:
        return MenuScreen(restaurantId: restaurantId);
      case MenuViewType.adminList:
        return const AdminMenuScreen();
      case MenuViewType.publicWidget:
        return const PublicMenuView();
    }
  }
  
  /// Vérifier si l'utilisateur a les permissions d'administration pour les menus
  static bool _hasAdminPermissions(String? role) {
    if (role == null) return false;
    return ['admin', 'restaurateur'].contains(role.toLowerCase());
  }
  
  /// Obtenir le type de vue recommandé selon l'état d'authentification
  static MenuViewType getRecommendedViewType(WidgetRef ref) {
    final authState = ref.watch(simpleAuthProvider);
    
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      return MenuViewType.adminList;
    }
    
    return MenuViewType.publicList;
  }
}

/// Types de vues de menus disponibles
enum MenuViewType {
  publicList,    // Liste publique des menus
  adminList,     // Interface d'administration des menus
  publicWidget,  // Widget public pour affichage dans d'autres écrans
}

/// Extensions pour faciliter l'utilisation
extension MenuViewTypeExtension on MenuViewType {
  String get displayName {
    switch (this) {
      case MenuViewType.publicList:
        return 'Liste des menus';
      case MenuViewType.adminList:
        return 'Administration des menus';
      case MenuViewType.publicWidget:
        return 'Widget menus';
    }
  }
  
  bool get requiresAuth {
    switch (this) {
      case MenuViewType.publicList:
      case MenuViewType.publicWidget:
        return false;
      case MenuViewType.adminList:
        return true;
    }
  }
  
  List<String> get requiredRoles {
    switch (this) {
      case MenuViewType.publicList:
      case MenuViewType.publicWidget:
        return [];
      case MenuViewType.adminList:
        return ['admin', 'restaurateur'];
    }
  }
}

