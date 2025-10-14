import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';

/// Factory pour gérer l'affichage des vues de tableau de bord
/// Responsabilité unique : déterminer quel tableau de bord afficher selon le rôle de l'utilisateur
class DashboardViewFactory {
  
  /// Créer la vue de tableau de bord appropriée selon le rôle de l'utilisateur
  static Widget createDashboardView(WidgetRef ref) {
    // print('📊 [DashboardViewFactory] createDashboardView appelé');
    
    final authState = ref.watch(authProvider);
    // print('📊 [DashboardViewFactory] AuthState: ${authState.status}, Role: ${authState.role}');
    
    // Vérifier si l'utilisateur est authentifié
    if (!authState.isAuthenticated) {
      // print('📊 [DashboardViewFactory] Utilisateur non authentifié - Redirection vers auth');
      return _createUnauthorizedView();
    }
    
    final role = authState.role?.toLowerCase();
    // print('📊 [DashboardViewFactory] Rôle détecté: $role');
    
    // Créer le tableau de bord selon le rôle
    switch (role) {
      case 'admin':
        // print('📊 [DashboardViewFactory] Affichage: Dashboard Admin');
        return _createAdminDashboard(ref);
      case 'restaurateur':
        // print('📊 [DashboardViewFactory] Affichage: Dashboard Restaurateur');
        return _createRestaurateurDashboard(ref);
      case 'fournisseur':
        // print('📊 [DashboardViewFactory] Affichage: Dashboard Fournisseur');
        return _createFournisseurDashboard(ref);
      case 'client':
        // print('📊 [DashboardViewFactory] Affichage: Dashboard Client');
        return _createClientDashboard(ref);
      default:
        // print('📊 [DashboardViewFactory] Rôle non reconnu: $role - Dashboard par défaut');
        return _createDefaultDashboard(ref);
    }
  }
  
  /// Créer un tableau de bord spécifique selon le type
  static Widget createSpecificDashboardView(DashboardViewType type, WidgetRef ref) {
    // print('📊 [DashboardViewFactory] createSpecificDashboardView: $type');
    
    switch (type) {
      case DashboardViewType.admin:
        return _createAdminDashboard(ref);
      case DashboardViewType.restaurateur:
        return _createRestaurateurDashboard(ref);
      case DashboardViewType.fournisseur:
        return _createFournisseurDashboard(ref);
      case DashboardViewType.client:
        return _createClientDashboard(ref);
      case DashboardViewType.defaultView:
        return _createDefaultDashboard(ref);
    }
  }
  
  /// Obtenir le type de tableau de bord recommandé selon le rôle
  static DashboardViewType getRecommendedDashboardType(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return DashboardViewType.defaultView;
    }
    
    final role = authState.role?.toLowerCase();
    
    switch (role) {
      case 'admin':
        return DashboardViewType.admin;
      case 'restaurateur':
        return DashboardViewType.restaurateur;
      case 'fournisseur':
        return DashboardViewType.fournisseur;
      case 'client':
        return DashboardViewType.client;
      default:
        return DashboardViewType.defaultView;
    }
  }
  
  /// Vérifier si l'utilisateur a accès au tableau de bord
  static bool canAccessDashboard(WidgetRef ref, DashboardViewType type) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return type == DashboardViewType.defaultView;
    }
    
    final role = authState.role?.toLowerCase();
    
    switch (type) {
      case DashboardViewType.admin:
        return role == 'admin';
      case DashboardViewType.restaurateur:
        return ['admin', 'restaurateur'].contains(role);
      case DashboardViewType.fournisseur:
        return ['admin', 'fournisseur'].contains(role);
      case DashboardViewType.client:
        return ['admin', 'restaurateur', 'fournisseur', 'client'].contains(role);
      case DashboardViewType.defaultView:
        return true;
    }
  }
  
  // Méthodes privées pour créer les différents tableaux de bord
  
  static Widget _createAdminDashboard(WidgetRef ref) {
    return const DashboardScreen(); // TODO: Spécialiser pour admin
  }
  
  static Widget _createRestaurateurDashboard(WidgetRef ref) {
    return const DashboardScreen(); // TODO: Spécialiser pour restaurateur
  }
  
  static Widget _createFournisseurDashboard(WidgetRef ref) {
    return const DashboardScreen(); // TODO: Spécialiser pour fournisseur
  }
  
  static Widget _createClientDashboard(WidgetRef ref) {
    return const DashboardScreen(); // TODO: Spécialiser pour client
  }
  
  static Widget _createDefaultDashboard(WidgetRef ref) {
    return const DashboardScreen();
  }
  
  static Widget _createUnauthorizedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès non autorisé'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Accès non autorisé',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vous devez être connecté pour accéder au tableau de bord',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Types de tableaux de bord disponibles
enum DashboardViewType {
  admin,         // Tableau de bord administrateur
  restaurateur,  // Tableau de bord restaurateur
  fournisseur,   // Tableau de bord fournisseur
  client,        // Tableau de bord client
  defaultView,   // Vue par défaut
}

/// Extensions pour faciliter l'utilisation
extension DashboardViewTypeExtension on DashboardViewType {
  String get displayName {
    switch (this) {
      case DashboardViewType.admin:
        return 'Tableau de bord Admin';
      case DashboardViewType.restaurateur:
        return 'Tableau de bord Restaurateur';
      case DashboardViewType.fournisseur:
        return 'Tableau de bord Fournisseur';
      case DashboardViewType.client:
        return 'Tableau de bord Client';
      case DashboardViewType.defaultView:
        return 'Tableau de bord';
    }
  }
  
  bool get requiresAuth {
    switch (this) {
      case DashboardViewType.defaultView:
        return false;
      case DashboardViewType.admin:
      case DashboardViewType.restaurateur:
      case DashboardViewType.fournisseur:
      case DashboardViewType.client:
        return true;
    }
  }
  
  List<String> get requiredRoles {
    switch (this) {
      case DashboardViewType.admin:
        return ['admin'];
      case DashboardViewType.restaurateur:
        return ['admin', 'restaurateur'];
      case DashboardViewType.fournisseur:
        return ['admin', 'fournisseur'];
      case DashboardViewType.client:
        return ['admin', 'restaurateur', 'fournisseur', 'client'];
      case DashboardViewType.defaultView:
        return [];
    }
  }
}

