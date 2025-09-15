import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simple_auth_provider.dart';
import '../screens/service/services_screen.dart';
import '../widgets/services/public_services_view.dart';

/// Factory pour gérer l'affichage des vues de services
/// Responsabilité unique : déterminer quelle vue de service afficher selon l'état d'auth et les permissions
class ServiceViewFactory {
  
  /// Créer la vue de service appropriée selon l'état d'authentification et les permissions
  static Widget createServiceView(WidgetRef ref, {int? serviceId}) {
    print('🛠️ [ServiceViewFactory] createServiceView appelé');
    print('🛠️ [ServiceViewFactory] serviceId: $serviceId');
    
    final authState = ref.watch(simpleAuthProvider);
    print('🛠️ [ServiceViewFactory] AuthState: ${authState.status}, Role: ${authState.role}');
    
    // Pour l'instant, tous les utilisateurs voient la même vue
    // TODO: Implémenter une vue admin pour les services si nécessaire
    print('🛠️ [ServiceViewFactory] Affichage: ServicesScreen');
    return const ServicesScreen();
  }
  
  /// Créer une vue de service spécifique
  static Widget createSpecificServiceView(ServiceViewType type, WidgetRef ref, {int? serviceId}) {
    print('🛠️ [ServiceViewFactory] createSpecificServiceView: $type');
    
    switch (type) {
      case ServiceViewType.publicList:
        return const ServicesScreen();
      case ServiceViewType.adminList:
        // TODO: Implémenter AdminServiceScreen si nécessaire
        return const ServicesScreen();
      case ServiceViewType.publicWidget:
        return const PublicServicesView();
    }
  }
  
  /// Vérifier si l'utilisateur a les permissions d'administration pour les services
  static bool _hasAdminPermissions(String? role) {
    if (role == null) return false;
    return ['admin'].contains(role.toLowerCase());
  }
  
  /// Obtenir le type de vue recommandé selon l'état d'authentification
  static ServiceViewType getRecommendedViewType(WidgetRef ref) {
    final authState = ref.watch(simpleAuthProvider);
    
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      return ServiceViewType.adminList;
    }
    
    return ServiceViewType.publicList;
  }
  
  /// Vérifier si l'utilisateur peut créer des services
  static bool canCreateServices(WidgetRef ref) {
    final authState = ref.watch(simpleAuthProvider);
    
    if (!authState.isAuthenticated) return false;
    
    final role = authState.role?.toLowerCase();
    return ['admin'].contains(role);
  }
  
  /// Vérifier si l'utilisateur peut gérer un service spécifique
  static bool canManageService(WidgetRef ref, int serviceId) {
    final authState = ref.watch(simpleAuthProvider);
    
    if (!authState.isAuthenticated) return false;
    
    final role = authState.role?.toLowerCase();
    
    // Seuls les admins peuvent gérer les services
    return role == 'admin';
  }
}

/// Types de vues de services disponibles
enum ServiceViewType {
  publicList,    // Liste publique des services
  adminList,     // Interface d'administration des services
  publicWidget,  // Widget public pour affichage dans d'autres écrans
}

/// Extensions pour faciliter l'utilisation
extension ServiceViewTypeExtension on ServiceViewType {
  String get displayName {
    switch (this) {
      case ServiceViewType.publicList:
        return 'Liste des services';
      case ServiceViewType.adminList:
        return 'Administration des services';
      case ServiceViewType.publicWidget:
        return 'Widget services';
    }
  }
  
  bool get requiresAuth {
    switch (this) {
      case ServiceViewType.publicList:
      case ServiceViewType.publicWidget:
        return false;
      case ServiceViewType.adminList:
        return true;
    }
  }
  
  List<String> get requiredRoles {
    switch (this) {
      case ServiceViewType.publicList:
      case ServiceViewType.publicWidget:
        return [];
      case ServiceViewType.adminList:
        return ['admin'];
    }
  }
}

