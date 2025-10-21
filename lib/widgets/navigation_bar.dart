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
    final userRole = authState.role?.toLowerCase();
    
    // Calculer les indices selon le rôle
    int baseIndex = 0;
    int restaurantsIndex = -1;
    int eventsIndex = -1;
    int profileIndex = -1;
    int ordersIndex = -1;
    
    // Accueil (toujours index 0)
    baseIndex = 0;
    
    // Menus (toujours index 1)
    baseIndex = 1;
    
    // Restaurants (index 2 seulement si pas fournisseur)
    if (userRole != 'fournisseur') {
      restaurantsIndex = 2;
      baseIndex = 2;
    }
    
    // Événements (index suivant seulement si pas fournisseur)
    if (userRole != 'fournisseur') {
      eventsIndex = baseIndex + 1;
      baseIndex = eventsIndex;
    }
    
    // Profil (toujours le dernier avant commandes)
    profileIndex = baseIndex + 1;
    
    // Commandes (seulement si connecté)
    if (authState.isAuthenticated) {
      ordersIndex = profileIndex + 1;
    }
    
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/menus');
        break;
      default:
        if (index == restaurantsIndex) {
          context.go('/restaurants');
        } else if (index == eventsIndex) {
          context.go('/evenements');
        } else if (index == profileIndex) {
          // Navigation intelligente vers le profil selon l'état d'authentification
          if (authState.isAuthenticated) {
            context.go('/profil?view=profile');
          } else {
            context.go('/profil');
          }
        } else if (index == ordersIndex) {
          // Bouton "Mes commandes" - seulement visible pour les clients connectés
          context.go('/commandes');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surveiller l'état d'authentification pour mettre à jour l'interface
    final authState = ref.watch(authProvider);
    
    // Créer la liste des destinations selon l'état d'authentification et le rôle
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
    ];
    
    // Ajouter "Restaurants" seulement si l'utilisateur n'est pas fournisseur
    final userRole = authState.role?.toLowerCase();
    if (userRole != 'fournisseur') {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: 'Restaurants',
        ),
      );
    }
    
    // Ajouter "Événements" seulement si l'utilisateur n'est pas fournisseur
    if (userRole != 'fournisseur') {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'Événements',
        ),
      );
    }
    
    // Ajouter le profil/connexion
    destinations.add(
      NavigationDestination(
        icon: Icon(authState.isAuthenticated ? Icons.person : Icons.login),
        selectedIcon: Icon(authState.isAuthenticated ? Icons.person : Icons.login),
        label: authState.isAuthenticated ? 'Profil' : 'Connexion',
      ),
    );

    // Ajouter le bouton "Mes commandes" pour les utilisateurs connectés (clients, restaurateurs, fournisseurs)
    if (authState.isAuthenticated) {
      final role = authState.role?.toLowerCase();
      if (role == 'client' || role == 'restaurateur' || role == 'fournisseur' || role == 'admin') {
        destinations.add(
          const NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Commandes',
          ),
        );
      }
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