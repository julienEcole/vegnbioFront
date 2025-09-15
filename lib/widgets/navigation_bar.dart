import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Suppression temporaire de la logique d'authentification pour tester
    
    return NavigationBar(
      backgroundColor: Colors.green,
      indicatorColor: Colors.white,
      elevation: 8,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Menus',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'Événements',
        ),
        NavigationDestination(
          icon: Icon(Icons.room_service_outlined),
          selectedIcon: Icon(Icons.room_service),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: 'Restaurants',
        ),
        NavigationDestination(
          icon: Icon(Icons.login_outlined),
          selectedIcon: Icon(Icons.login),
          label: 'Connexion',
        ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}