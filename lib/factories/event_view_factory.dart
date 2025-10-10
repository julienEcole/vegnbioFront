import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/events_admin_dashboard.dart';
import '../widgets/events/public_events_view.dart';

/// Factory pour gérer l'affichage des vues d'événements
/// Responsabilité unique : déterminer quelle vue d'événement afficher selon l'état d'auth et les permissions
class EventViewFactory {
  
  /// Créer la vue d'événement appropriée selon l'état d'authentification et les permissions
  static Widget createEventView(WidgetRef ref, {int? eventId}) {
    print('🎉 [EventViewFactory] createEventView appelé');
    print('🎉 [EventViewFactory] eventId: $eventId');
    
    final authState = ref.watch(authProvider);
    print('🎉 [EventViewFactory] AuthState: ${authState.status}, Role: ${authState.role}');
    
    // Si l'utilisateur est authentifié et a les permissions d'administration
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      print('🎉 [EventViewFactory] Affichage: EventAdminDashboard (Admin/Restaurateur)');
      return const EventAdminDashboard();
    }
    
    // Sinon, afficher la vue publique
    print('🎉 [EventViewFactory] Affichage: EventsScreen (Public)');
    return const EventsScreen();
  }
  
  /// Créer une vue d'événement spécifique
  static Widget createSpecificEventView(EventViewType type, WidgetRef ref, {int? eventId}) {
    print('🎉 [EventViewFactory] createSpecificEventView: $type');
    
    switch (type) {
      case EventViewType.publicList:
        return const EventsScreen();
      case EventViewType.adminList:
        return const EventAdminDashboard();
      case EventViewType.publicWidget:
        return const PublicEventsView();
    }
  }
  
  /// Vérifier si l'utilisateur a les permissions d'administration pour les événements
  static bool _hasAdminPermissions(String? role) {
    if (role == null) return false;
    return ['admin', 'restaurateur'].contains(role.toLowerCase());
  }
  
  /// Obtenir le type de vue recommandé selon l'état d'authentification
  static EventViewType getRecommendedViewType(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.isAuthenticated && _hasAdminPermissions(authState.role)) {
      return EventViewType.adminList;
    }
    
    return EventViewType.publicList;
  }
  
  /// Obtenir le type de vue automatique selon le rôle de l'utilisateur
  static EventViewType getAutoViewType(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return EventViewType.publicList;
    }
    
    final role = authState.role?.toLowerCase();
    
    // Les utilisateurs avec permissions d'administration voient l'interface admin
    if (_hasAdminPermissions(role)) {
      return EventViewType.adminList;
    }
    
    // Par défaut, vue publique
    return EventViewType.publicList;
  }
  
  /// Vérifier si l'utilisateur peut créer des événements
  static bool canCreateEvents(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) return false;
    
    final role = authState.role?.toLowerCase();
    return ['admin', 'restaurateur'].contains(role);
  }
  
  /// Vérifier si l'utilisateur peut gérer un événement spécifique
  static bool canManageEvent(WidgetRef ref, int eventId) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) return false;
    
    final role = authState.role?.toLowerCase();
    
    // Les admins peuvent tout gérer
    if (role == 'admin') return true;
    
    // Les restaurateurs peuvent gérer leurs propres événements
    // TODO: Implémenter la vérification de propriété de l'événement
    if (role == 'restaurateur') {
      return true; // Temporaire
    }
    
    return false;
  }
}

/// Types de vues d'événements disponibles
enum EventViewType {
  publicList,    // Liste publique des événements
  adminList,     // Interface d'administration des événements
  publicWidget,  // Widget public pour affichage dans d'autres écrans
}

/// Extensions pour faciliter l'utilisation
extension EventViewTypeExtension on EventViewType {
  String get displayName {
    switch (this) {
      case EventViewType.publicList:
        return 'Liste des événements';
      case EventViewType.adminList:
        return 'Administration des événements';
      case EventViewType.publicWidget:
        return 'Widget événements';
    }
  }
  
  bool get requiresAuth {
    switch (this) {
      case EventViewType.publicList:
      case EventViewType.publicWidget:
        return false;
      case EventViewType.adminList:
        return true;
    }
  }
  
  List<String> get requiredRoles {
    switch (this) {
      case EventViewType.publicList:
      case EventViewType.publicWidget:
        return [];
      case EventViewType.adminList:
        return ['admin', 'restaurateur'];
    }
  }
}

