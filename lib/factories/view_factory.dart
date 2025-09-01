import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/public_menu_view.dart';
import '../widgets/public_restaurant_view.dart';
import '../widgets/public_events_view.dart';
import '../widgets/public_services_view.dart';
import '../screens/menu_screen.dart';
import '../screens/restaurants_screen.dart';
import '../screens/events_screen.dart';
import '../screens/services_screen.dart';

/// Factory pour créer les vues appropriées selon le rôle et le type de page
class ViewFactory {
  static Widget createView({
    required String pageType,
    required bool isAuthenticated,
    String? userRole,
    Map<String, dynamic>? parameters,
  }) {
    // Si l'utilisateur n'est pas authentifié, retourner la vue publique
    if (!isAuthenticated) {
      return _createPublicView(pageType, parameters);
    }

    // Si l'utilisateur est authentifié, vérifier les permissions
    if (_hasAccess(pageType, userRole)) {
      return _createAuthenticatedView(pageType, parameters);
    } else {
      // Rôle insuffisant, retourner la vue publique
      return _createPublicView(pageType, parameters);
    }
  }

  /// Créer une vue publique selon le type de page
  static Widget _createPublicView(String pageType, Map<String, dynamic>? parameters) {
    switch (pageType.toLowerCase()) {
      case 'menus':
        return const PublicMenuView();
      case 'restaurants':
        final highlightRestaurantId = parameters?['highlightRestaurantId'] as int?;
        return PublicRestaurantView(highlightRestaurantId: highlightRestaurantId);
      case 'events':
        return const PublicEventsView();
      case 'services':
        return const PublicServicesView();
      default:
        // Vue par défaut si le type n'est pas reconnu
        return _createDefaultPublicView();
    }
  }

  /// Créer une vue authentifiée selon le type de page
  static Widget _createAuthenticatedView(String pageType, Map<String, dynamic>? parameters) {
    switch (pageType.toLowerCase()) {
      case 'menus':
        final restaurantId = parameters?['restaurantId'] as int?;
        return MenuScreen(restaurantId: restaurantId);
      case 'restaurants':
        final highlightRestaurantId = parameters?['highlightRestaurantId'] as int?;
        return RestaurantsScreen(highlightRestaurantId: highlightRestaurantId);
      case 'events':
        return const EventsScreen();
      case 'services':
        return const ServicesScreen();
      default:
        // Vue par défaut si le type n'est pas reconnu
        return _createDefaultAuthenticatedView();
    }
  }

  /// Vérifier si l'utilisateur a accès à la page selon son rôle
  static bool _hasAccess(String pageType, String? userRole) {
    if (userRole == null) return false;

    switch (pageType.toLowerCase()) {
      case 'menus':
        return ['admin', 'restaurateur'].contains(userRole);
      case 'restaurants':
        return ['admin', 'restaurateur'].contains(userRole);
      case 'events':
        return ['admin', 'restaurateur', 'fournisseur'].contains(userRole);
      case 'services':
        return ['admin', 'restaurateur', 'fournisseur'].contains(userRole);
      default:
        return false;
    }
  }

  /// Créer une vue publique par défaut
  static Widget _createDefaultPublicView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès Public'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Vue publique par défaut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Connectez-vous pour accéder aux fonctionnalités complètes',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Créer une vue authentifiée par défaut
  static Widget _createDefaultAuthenticatedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès Authentifié'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Vue authentifiée par défaut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vous êtes connecté avec les fonctionnalités complètes',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider pour la factory de vues
final viewFactoryProvider = Provider<ViewFactory>((ref) => ViewFactory());
