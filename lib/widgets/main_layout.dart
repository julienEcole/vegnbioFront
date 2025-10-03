import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/navigation_bar.dart';
import '../providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialiser l'authentification au démarrage du layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        print('🔐 [MainLayout] Initialisation de l\'authentification...');
        ref.read(authProvider.notifier).checkAuthStatus();
        _isInitialized = true;
      }
    });
  }

  int _getSelectedIndex() {
    final authState = ref.watch(authProvider);
    
    switch (widget.currentRoute) {
      case '/':
        return 0;
      case '/menus':
        return 1;
      case '/restaurants':
        return 2;
      case '/evenements':
        return 3;
      case '/profil':
        return 4;
      case '/commandes':
        // Vérifier si l'utilisateur est connecté
        if (authState.isAuthenticated) {
          final role = authState.role?.toLowerCase();
          if (role == 'client' || role == 'restaurateur' || role == 'fournisseur' || role == 'admin') {
            return 5; // Index pour les commandes
          }
        }
        return 4; // Rediriger vers le profil si pas connecté
      default:
        return 0;
    }
  }

  void _onDestinationSelected(int index) {
    // La navigation est maintenant gérée par CustomNavigationBar
    // Cette méthode est conservée pour la compatibilité mais ne fait rien
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _getSelectedIndex(),
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
