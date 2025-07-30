import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentLocation = GoRouterState.of(context).uri.path;
    
    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.white),
          selectedIcon: Icon(Icons.home, color: Colors.white),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined, color: Colors.white),
          selectedIcon: Icon(Icons.restaurant_menu, color: Colors.white),
          label: 'Menus',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined, color: Colors.white),
          selectedIcon: Icon(Icons.event, color: Colors.white),
          label: 'Événements',
        ),
        NavigationDestination(
          icon: Icon(Icons.room_service_outlined, color: Colors.white),
          selectedIcon: Icon(Icons.room_service, color: Colors.white),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined, color: Colors.white),
          selectedIcon: Icon(Icons.location_on, color: Colors.white),
          label: 'Restaurants',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: Colors.white),
          selectedIcon: Icon(Icons.person, color: Colors.white),
          label: 'Profil',
        ),
      ],
      selectedIndex: _getSelectedIndex(currentLocation),
      onDestinationSelected: (int index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/menus');
            break;
          case 2:
            context.go('/evenements');
            break;
          case 3:
            context.go('/services');
            break;
          case 4:
            context.go('/restaurants');
            break;
          case 5:
            context.go('/profil');
            break;
        }
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case '/':
        return 0;
      case '/menus':
        return 1;
      case '/evenements':
        return 2;
      case '/services':
        return 3;
      case '/restaurants':
        return 4;
      case '/profil':
        return 5;
      default:
        return 0;
    }
  }
}