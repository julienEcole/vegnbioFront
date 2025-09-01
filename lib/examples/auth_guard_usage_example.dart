// Exemple d'utilisation du système de protection d'authentification
// Ce fichier montre comment utiliser le AuthGuardWrapper dans différents scénarios

import 'package:flutter/material.dart';
import '../widgets/auth_guard_wrapper.dart';
import '../widgets/public_menu_view.dart';
import '../widgets/public_restaurant_view.dart';
import '../widgets/public_events_view.dart';
import '../widgets/public_services_view.dart';

/// Exemple 1: Page admin avec vue publique de fallback
class AdminMenuPageExample extends StatelessWidget {
  const AdminMenuPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildAdminMenuPage(context).authGuard(
      pageType: 'admin', // Nécessite un rôle admin
      publicView: const PublicMenuView(), // Vue publique si token invalide
      requireAuth: true, // Authentification requise
      customMessage: 'Accès aux menus nécessite une authentification admin',
    );
  }

  Widget _buildAdminMenuPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menus - Admin')),
      body: const Center(
        child: Text('Page admin des menus avec fonctionnalités complètes'),
      ),
    );
  }
}

/// Exemple 2: Page restaurateur avec vue publique de fallback
class RestaurateurPageExample extends StatelessWidget {
  const RestaurateurPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildRestaurateurPage(context).authGuard(
      pageType: 'restaurateur', // Nécessite un rôle restaurateur
      publicView: const PublicRestaurantView(), // Vue publique si token invalide
      requireAuth: true, // Authentification requise
      customMessage: 'Accès aux fonctionnalités restaurateur nécessite une authentification',
    );
  }

  Widget _buildRestaurateurPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurateur')),
      body: const Center(
        child: Text('Page restaurateur avec fonctionnalités de gestion'),
      ),
    );
  }
}

/// Exemple 3: Page fournisseur avec vue publique de fallback
class FournisseurPageExample extends StatelessWidget {
  const FournisseurPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFournisseurPage(context).authGuard(
      pageType: 'fournisseur', // Nécessite un rôle fournisseur
      publicView: const PublicServicesView(), // Vue publique si token invalide
      requireAuth: true, // Authentification requise
      customMessage: 'Accès aux fonctionnalités fournisseur nécessite une authentification',
    );
  }

  Widget _buildFournisseurPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseur')),
      body: const Center(
        child: Text('Page fournisseur avec fonctionnalités de gestion'),
      ),
    );
  }
}

/// Exemple 4: Page publique avec fonctionnalités admin optionnelles
class PublicPageWithAdminFeaturesExample extends StatelessWidget {
  const PublicPageWithAdminFeaturesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPublicPage(context).authGuard(
      pageType: 'public', // Page publique
      publicView: const PublicEventsView(), // Vue publique si token invalide
      requireAuth: false, // Pas d'authentification requise
      customMessage: 'Connectez-vous pour accéder aux fonctionnalités complètes',
    );
  }

  Widget _buildPublicPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          // Bouton admin visible seulement si authentifié
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implémenter l'ajout d'événement
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Page publique avec fonctionnalités admin optionnelles'),
      ),
    );
  }
}

/// Exemple 5: Page sans vue publique (redirection directe)
class AdminOnlyPageExample extends StatelessWidget {
  const AdminOnlyPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildAdminOnlyPage(context).authGuard(
      pageType: 'admin', // Nécessite un rôle admin
      // Pas de publicView - redirection directe vers /profil si token invalide
      requireAuth: true, // Authentification requise
      customMessage: 'Cette page nécessite une authentification admin',
    );
  }

  Widget _buildAdminOnlyPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Only')),
      body: const Center(
        child: Text('Page accessible uniquement aux administrateurs'),
      ),
    );
  }
}

/// Exemple 6: Page avec callbacks personnalisés
class PageWithCallbacksExample extends StatelessWidget {
  const PageWithCallbacksExample({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPageWithCallbacks(context).authGuard(
      pageType: 'admin',
      publicView: const PublicMenuView(),
      requireAuth: true,
      customMessage: 'Accès refusé',
      onAccessDenied: () {
        print('Accès refusé - callback personnalisé');
        // Logique personnalisée en cas d'accès refusé
      },
      onTokenInvalid: () {
        print('Token invalide - callback personnalisé');
        // Logique personnalisée en cas de token invalide
      },
    );
  }

  Widget _buildPageWithCallbacks(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page avec callbacks')),
      body: const Center(
        child: Text('Page avec callbacks personnalisés'),
      ),
    );
  }
}

/// Guide d'utilisation du système de protection d'authentification
class AuthGuardUsageGuide extends StatelessWidget {
  const AuthGuardUsageGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide d\'utilisation AuthGuard')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guide d\'utilisation du système de protection d\'authentification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Le système AuthGuardWrapper permet de protéger les pages en vérifiant :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• La validité du token d\'authentification'),
            Text('• Le rôle de l\'utilisateur (admin, restaurateur, fournisseur, client)'),
            Text('• L\'accès aux fonctionnalités selon le type de page'),
            SizedBox(height: 16),
            Text(
              'Types de pages supportés :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• "admin" : Accès admin ou restaurateur'),
            Text('• "restaurateur" : Accès restaurateur ou admin'),
            Text('• "fournisseur" : Accès fournisseur ou admin'),
            Text('• "client" : Accès client ou admin'),
            Text('• "public" : Accès public avec fonctionnalités optionnelles'),
            SizedBox(height: 16),
            Text(
              'Comportement en cas de token invalide :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Si une vue publique est fournie : affichage de la vue publique'),
            Text('• Si aucune vue publique : redirection vers /profil'),
            Text('• Affichage d\'un popup temporaire avec message d\'erreur'),
            SizedBox(height: 16),
            Text(
              'Exemple d\'utilisation :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Widget build(BuildContext context) {\n'
              '  return _buildMyPage(context).authGuard(\n'
              '    pageType: \'admin\',\n'
              '    publicView: PublicView(),\n'
              '    requireAuth: true,\n'
              '    customMessage: \'Message personnalisé\',\n'
              '  );\n'
              '}',
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
