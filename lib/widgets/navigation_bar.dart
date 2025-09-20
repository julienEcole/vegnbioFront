import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class CustomNavigationBar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  void _handleNavigation(BuildContext context, WidgetRef ref, int index) {
    final authState = ref.read(authProvider);
    
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/menus');
        break;
      case 2:
        context.go('/restaurants');
        break;
      case 3:
        context.go('/evenements');
        break;
      case 4:
        // Navigation intelligente vers le profil selon l'état d'authentification
        if (authState.isAuthenticated) {
          context.go('/profil?view=profile');
        } else {
          context.go('/profil');
        }
        break;
      case 5:
        // Bouton "Mes commandes" - seulement visible pour les clients connectés
        context.go('/commandes');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surveiller l'état d'authentification pour mettre à jour l'interface
    final authState = ref.watch(authProvider);
    
    // Créer la liste des destinations selon l'état d'authentification
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      const NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: 'Menus',
      ),
      const NavigationDestination(
        icon: Icon(Icons.location_on_outlined),
        selectedIcon: Icon(Icons.location_on),
        label: 'Restaurants',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Événements',
      ),
      NavigationDestination(
        icon: Icon(authState.isAuthenticated ? Icons.person : Icons.login),
        selectedIcon: Icon(authState.isAuthenticated ? Icons.person : Icons.login),
        label: authState.isAuthenticated ? 'Profil' : 'Connexion',
      ),
    ];

    // Ajouter le bouton "Mes commandes" seulement pour les clients connectés
    if (authState.isAuthenticated && authState.role?.toLowerCase() == 'client') {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag),
          label: 'Commandes',
        ),
      );
    }

    return NavigationBar(
      backgroundColor: Colors.green,
      indicatorColor: Colors.white,
      elevation: 8,
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _handleNavigation(context, ref, index),
    );
  }
}