import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';

/// Widget pour protéger les vues qui nécessitent une authentification
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final List<String>? requiredRoles;
  final Widget? fallbackWidget;
  final bool requireAuth;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredRoles,
    this.fallbackWidget,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Si l'authentification n'est pas requise, afficher directement
    if (!requireAuth) {
      return child;
    }
    
    // Si en cours de chargement, afficher un indicateur
    if (authState.isLoading) {
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
    
    // Si non authentifié, afficher le widget de fallback ou rediriger
    if (!authState.isAuthenticated) {
      if (fallbackWidget != null) {
        return fallbackWidget!;
      }
      
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Accès non autorisé',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous devez être connecté pour accéder à cette page.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Rediriger vers la page de connexion
                  Navigator.of(context).pushNamed('/profil');
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Si des rôles spécifiques sont requis, vérifier les permissions
    if (requiredRoles != null && requiredRoles!.isNotEmpty) {
      final userRole = authState.userRole;
      
      if (userRole == null || !requiredRoles!.contains(userRole)) {
        if (fallbackWidget != null) {
          return fallbackWidget!;
        }
        
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Permissions insuffisantes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous devez avoir le rôle ${requiredRoles!.join(' ou ')} pour accéder à cette page.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre rôle actuel: ${userRole ?? 'Non défini'}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    // Si tout est OK, afficher le contenu
    return child;
  }
}

/// Widget pour protéger les vues admin
class AdminGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const AdminGuard({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      requiredRoles: AppConfig.adminRoles,
      fallbackWidget: fallbackWidget,
      child: child,
    );
  }
}

/// Widget pour protéger les vues restaurateur
class RestaurateurGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const RestaurateurGuard({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      requiredRoles: AppConfig.restaurateurRoles,
      fallbackWidget: fallbackWidget,
      child: child,
    );
  }
}

/// Widget pour protéger les vues fournisseur
class FournisseurGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const FournisseurGuard({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      requiredRoles: AppConfig.fournisseurRoles,
      fallbackWidget: fallbackWidget,
      child: child,
    );
  }
}

/// Widget pour protéger les vues client et supérieures
class ClientGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const ClientGuard({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      requiredRoles: AppConfig.clientRoles,
      fallbackWidget: fallbackWidget,
      child: child,
    );
  }
}

/// Widget pour protéger les vues qui nécessitent un rôle supérieur à client
class ProtectedViewGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallbackWidget;

  const ProtectedViewGuard({
    super.key,
    required this.child,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return fallbackWidget ?? const SizedBox.shrink();
    }
    
    final userRole = authState.userRole;
    final canAccess = userRole != null && 
        (AppConfig.restaurateurRoles.contains(userRole) || 
         AppConfig.fournisseurRoles.contains(userRole) || 
         AppConfig.adminRoles.contains(userRole));
    
    if (!canAccess) {
      return fallbackWidget ?? const SizedBox.shrink();
    }
    
    return child;
  }
}
