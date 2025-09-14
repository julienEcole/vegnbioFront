import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/web_logger.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/menu/public_menu_view.dart';
import '../widgets/menu/authenticated_menu_view.dart';
import '../widgets/restaurant/public_restaurant_view.dart';
import '../widgets/public_events_view.dart';
import '../widgets/public_services_view.dart';
import '../widgets/authenticated_events_view.dart';
import '../widgets/authenticated_services_view.dart';
import '../widgets/public_home_view.dart';

/// Factory simplifiée qui utilise les providers pour gérer l'authentification
class SimpleViewFactory {
  
  /// Créer une vue selon l'état d'authentification des providers
  static Widget createView({
    required String pageType,
    Map<String, dynamic>? parameters,
    Widget? fallbackView,
    bool requireAuth = true,
  }) {
    print('🚨 [SimpleViewFactory] CREATEVIEW APPELÉ !');
    print('🚨 PageType: $pageType, RequireAuth: $requireAuth');
    
    WebLogger.logWithEmoji('[SimpleViewFactory] CREATEVIEW APPELÉ !', '🚨', color: '#9C27B0');
    WebLogger.logStyled('PageType: $pageType', color: '#9C27B0');
    WebLogger.logStyled('RequireAuth: $requireAuth', color: '#9C27B0');

    return _SimpleViewFactoryWidget(
      pageType: pageType,
      parameters: parameters,
      fallbackView: fallbackView,
      requireAuth: requireAuth,
    );
  }
}

/// Widget interne qui utilise les providers pour gérer l'authentification
class _SimpleViewFactoryWidget extends ConsumerWidget {
  final String pageType;
  final Map<String, dynamic>? parameters;
  final Widget? fallbackView;
  final bool requireAuth;

  const _SimpleViewFactoryWidget({
    required this.pageType,
    this.parameters,
    this.fallbackView,
    required this.requireAuth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏭 [SimpleViewFactory] ===== BUILD =====');
    print('🏭 PageType: $pageType, RequireAuth: $requireAuth');
    
    WebLogger.logWithEmoji('[SimpleViewFactory] ===== BUILD =====', '🏭', color: '#9C27B0');
    WebLogger.logStyled('PageType: $pageType', color: '#9C27B0');
    WebLogger.logStyled('RequireAuth: $requireAuth', color: '#9C27B0');

    // Écouter l'état d'authentification
    final authState = ref.watch(authStateProvider);
    
    print('🏭 AuthState - Loading: ${authState.isLoading}');
    print('🏭 AuthState - Authenticated: ${authState.isAuthenticated}');
    print('🏭 AuthState - Role: ${authState.userRole}');
    
    WebLogger.logStyled('AuthState - Loading: ${authState.isLoading}', color: '#9C27B0');
    WebLogger.logStyled('AuthState - Authenticated: ${authState.isAuthenticated}', color: '#9C27B0');
    WebLogger.logStyled('AuthState - Role: ${authState.userRole}', color: '#9C27B0');

    // Affichage du loading
    if (authState.isLoading) {
      WebLogger.logStyled('→ Affichage LOADING', color: '#9C27B0');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification de l\'authentification...'),
            ],
          ),
        ),
      );
    }

    // Gestion des erreurs
    if (authState.error != null) {
      WebLogger.logWithEmoji('Erreur auth: ${authState.error}', '❌', color: '#F44336');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Erreur d\'authentification'),
              SizedBox(height: 8),
              Text(authState.error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authStateProvider.notifier).refresh(),
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildViewFromAuthState(context, authState);
  }

  /// Construire la vue appropriée selon l'état d'authentification
  Widget _buildViewFromAuthState(BuildContext context, AuthState authState) {
    WebLogger.logWithEmoji('[SimpleViewFactory] ===== _buildViewFromAuthState =====', '🏗️', color: '#9C27B0');
    WebLogger.logStyled('PageType: $pageType', color: '#9C27B0');
    WebLogger.logStyled('Authenticated: ${authState.isAuthenticated}', color: '#9C27B0');
    WebLogger.logStyled('Role: ${authState.userRole}', color: '#9C27B0');

    // Si l'authentification est requise mais l'utilisateur n'est pas connecté
    if (requireAuth && !authState.isAuthenticated) {
      WebLogger.logWithEmoji('→ Authentification requise mais utilisateur non connecté', '🔒', color: '#FF5722');
      return _buildAuthRequiredView(context);
    }

    // Sélectionner la vue selon le type de page et l'état d'authentification
    switch (pageType.toLowerCase()) {
      case 'home':
        WebLogger.logWithEmoji('→ Construction PublicHomeView', '🏠', color: '#00BCD4');
        return const PublicHomeView();
        
      case 'menu':
      case 'menus':
        if (authState.isAuthenticated) {
          WebLogger.logWithEmoji('→ Construction AuthenticatedMenuView', '🍽️', color: '#4CAF50');
          // Extraire restaurantId des paramètres
          final restaurantId = parameters?['restaurantId'] as int?;
          return AuthenticatedMenuView(restaurantId: restaurantId);
        } else {
          WebLogger.logWithEmoji('→ Construction PublicMenuView', '🍽️', color: '#00BCD4');
          return const PublicMenuView();
        }
        
      case 'restaurant':
      case 'restaurants':
        WebLogger.logWithEmoji('→ Construction PublicRestaurantView', '🏪', color: '#00BCD4');
        // Extraire highlightRestaurantId des paramètres
        final highlightRestaurantId = parameters?['highlightRestaurantId'] as int?;
        return PublicRestaurantView(highlightRestaurantId: highlightRestaurantId);
        
      case 'events':
      case 'evenements':
        if (authState.isAuthenticated) {
          WebLogger.logWithEmoji('→ Construction AuthenticatedEventsView', '🎉', color: '#4CAF50');
          return const AuthenticatedEventsView();
        } else {
          WebLogger.logWithEmoji('→ Construction PublicEventsView', '🎉', color: '#00BCD4');
          return const PublicEventsView();
        }
        
      case 'services':
        if (authState.isAuthenticated) {
          WebLogger.logWithEmoji('→ Construction AuthenticatedServicesView', '🛎️', color: '#4CAF50');
          return const AuthenticatedServicesView();
        } else {
          WebLogger.logWithEmoji('→ Construction PublicServicesView', '🛎️', color: '#00BCD4');
          return const PublicServicesView();
        }
        
      case 'profile':
      case 'profil':
        if (authState.isAuthenticated) {
          WebLogger.logWithEmoji('→ Construction ProfileView', '👤', color: '#4CAF50');
          // TODO: Créer ProfileView avec les providers
          return _buildProfileView(context);
        } else {
          WebLogger.logWithEmoji('→ Profil nécessite authentification', '🔒', color: '#FF5722');
          return _buildAuthRequiredView(context);
        }
        
      default:
        WebLogger.logWithEmoji('→ Type de page inconnu: $pageType', '❓', color: '#FF9800');
        return fallbackView ?? _buildUnknownPageView(context);
    }
  }

  /// Vue quand l'authentification est requise
  Widget _buildAuthRequiredView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification requise'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Vous devez être connecté pour accéder à cette page',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers la page de connexion
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Se connecter'),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // TODO: Naviguer vers la page d'inscription
                Navigator.pushNamed(context, '/register');
              },
              child: Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }

  /// Vue temporaire pour le profil
  Widget _buildProfileView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Page de profil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            Text('TODO: Implémenter avec ProfileProvider'),
          ],
        ),
      ),
    );
  }

  /// Vue pour les pages inconnues
  Widget _buildUnknownPageView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page introuvable'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text('Type de page: $pageType'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
