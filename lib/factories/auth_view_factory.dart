import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_default_screen.dart';
import '../screens/auth/auth_login_screen.dart';
import '../screens/auth/auth_register_screen.dart';
import '../screens/auth/auth_profile_screen.dart';

/// Factory pour gérer l'affichage des écrans d'authentification
/// Responsabilité unique : déterminer quel écran d'auth afficher selon l'état
class AuthViewFactory {
  /// Créer le widget d'authentification approprié selon l'état
  static Widget createAuthView(WidgetRef ref, {AuthViewType? forcedType}) {
    // print('🏗️ [AuthViewFactory] createAuthView appelé');
    
    final authState = ref.watch(authProvider);
    // print('🏗️ [AuthViewFactory] AuthState: ${authState.status}');
    
    // Si un type est forcé, l'utiliser directement
    if (forcedType != null) {
      // print('🏗️ [AuthViewFactory] Type forcé: $forcedType');
      return _createViewByType(forcedType, ref);
    }
    
    // Si l'état est non authentifié, afficher directement l'écran par défaut
    if (authState.status == AuthStatus.unauthenticated) {
      // print('🏗️ [AuthViewFactory] État non authentifié - Affichage écran par défaut');
      return const AuthDefaultScreen();
    }
    
    // Sinon, déterminer selon l'état d'authentification
    if (authState.isLoading) {
      // print('🏗️ [AuthViewFactory] État: Loading');
      return const AuthLoadingView();
    }
    
    if (authState.isAuthenticated) {
      // print('🏗️ [AuthViewFactory] État: Authenticated - Affichage SimpleProfileScreen');
      return const AuthProfileScreen();
    }
    
    if (authState.hasError) {
      // print('🏗️ [AuthViewFactory] État: Error - ${authState.errorMessage}');
      return AuthDefaultScreen(errorMessage: authState.errorMessage);
    }
    
    // Par défaut, afficher l'écran de connexion/inscription
    // print('🏗️ [AuthViewFactory] État: Par défaut - AuthDefaultScreen');
    return const AuthDefaultScreen();
  }
  
  /// Créer un écran spécifique selon le type
  static Widget _createViewByType(AuthViewType type, WidgetRef ref) {
    // print('🏗️ [AuthViewFactory] _createViewByType: $type');
    
    switch (type) {
      case AuthViewType.defaultView:
        return const AuthDefaultScreen();
      case AuthViewType.login:
        return const AuthLoginScreen();
      case AuthViewType.register:
        return const AuthRegisterScreen();
      case AuthViewType.profile:
        return const AuthProfileScreen(); // Utiliser SimpleProfileScreen
    }
  }
  
  /// Naviguer vers un écran d'authentification spécifique
  static void navigateToAuthView(BuildContext context, AuthViewType type) {
    // print('🔀 [AuthViewFactory] navigateToAuthView: $type');
    
    switch (type) {
      case AuthViewType.defaultView:
      case AuthViewType.login:
      case AuthViewType.register:
      case AuthViewType.profile:
        // Toujours naviguer vers /profil, la factory gérera l'affichage
        context.go('/profil');
        break;
    }
  }
}

/// Types d'écrans d'authentification disponibles
enum AuthViewType {
  defaultView,  // Écran par défaut avec boutons connexion/inscription
  login,        // Écran de connexion
  register,     // Écran d'inscription
  profile,      // Écran de profil utilisateur
}

/// Widget de chargement pour l'authentification
class AuthLoadingView extends StatelessWidget {
  const AuthLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Vérification de l\'authentification...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget wrapper pour les écrans d'authentification
/// Responsabilité : gérer la navigation et l'état global
class AuthViewWrapper extends ConsumerWidget {
  final AuthViewType? forcedType;
  
  const AuthViewWrapper({
    super.key,
    this.forcedType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: AuthViewFactory.createAuthView(ref, forcedType: forcedType),
      ),
    );
  }
}

/// Mixin pour faciliter l'utilisation de la factory dans les widgets
mixin AuthViewMixin {
  /// Obtenir le widget d'authentification approprié
  Widget getAuthView(WidgetRef ref, {AuthViewType? type}) {
    return AuthViewFactory.createAuthView(ref, forcedType: type);
  }
  
  /// Naviguer vers un écran d'authentification
  void navigateToAuth(BuildContext context, AuthViewType type) {
    AuthViewFactory.navigateToAuthView(context, type);
  }
}
