import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/simple_auth_provider.dart';
import '../factories/auth_view_factory.dart';
import '../screens/auth/auth_login_screen.dart';
import '../screens/auth/auth_register_screen.dart';

/// Service pour gérer la navigation liée à l'authentification
class AuthNavigationService {
  
  /// Naviguer vers l'authentification (profil ou connexion selon l'état)
  static void navigateToAuth(BuildContext context, WidgetRef ref) {
    print('🔐 [AuthNavigationService] navigateToAuth appelé');
    
    final authState = ref.read(simpleAuthProvider);
    print('🔐 [AuthNavigationService] État auth actuel: ${authState.status}');
    
    // Toujours naviguer vers /profil
    // AuthViewFactory gérera l'affichage selon l'état d'authentification
    print('🔐 [AuthNavigationService] Navigation vers /profil via AuthViewFactory');
    AuthViewFactory.navigateToAuthView(context, AuthViewType.profile);
  }

  /// Naviguer vers l'accueil
  static void navigateToHome(BuildContext context) {
    print('🏠 [AuthNavigationService] Navigation vers l\'accueil');
    context.go('/');
  }

  /// Naviguer vers une route spécifique après authentification
  static void navigateAfterAuth(BuildContext context, String? redirectPath) {
    final path = redirectPath ?? '/';
    print('🔀 [AuthNavigationService] Navigation après auth vers: $path');
    context.go(path);
  }

  /// Vérifier si l'utilisateur peut accéder à une route protégée
  static bool canAccessRoute(String route, String? userRole) {
    // Définir les routes protégées par rôle
    const Map<String, List<String>> protectedRoutes = {
      'admin': ['/admin'],
      'restaurateur': ['/dashboard/restaurateur'],
      'fournisseur': ['/dashboard/fournisseur'],
      'client': ['/profil', '/commandes'],
    };

    // Routes publiques accessibles à tous
    const List<String> publicRoutes = [
      '/',
      '/menus',
      '/restaurants', 
      '/evenements',
      '/services',
      '/profil', // Profil est accessible à tous (gère l'auth en interne)
    ];

    // Si c'est une route publique
    if (publicRoutes.contains(route)) {
      return true;
    }

    // Si l'utilisateur n'est pas connecté
    if (userRole == null) {
      return false;
    }

    // Vérifier si le rôle a accès à la route
    final allowedRoutes = protectedRoutes[userRole] ?? [];
    return allowedRoutes.any((allowedRoute) => route.startsWith(allowedRoute));
  }

  /// Rediriger vers la route appropriée selon le rôle
  static String getDefaultRouteForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return '/admin';
      case 'restaurateur':
        return '/dashboard/restaurateur';
      case 'fournisseur':
        return '/dashboard/fournisseur';
      case 'client':
      default:
        return '/';
    }
  }

  /// Naviguer vers l'écran de connexion
  static void navigateToLogin(BuildContext context) {
    print('🔐 [AuthNavigationService] Navigation vers l\'écran de connexion');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthLoginScreen()),
    );
  }

  /// Naviguer vers l'écran d'inscription
  static void navigateToRegister(BuildContext context) {
    print('📝 [AuthNavigationService] Navigation vers l\'écran d\'inscription');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthRegisterScreen()),
    );
  }
}