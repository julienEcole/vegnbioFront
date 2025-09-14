import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Enum pour les rôles utilisateur
enum UserRole { client, restaurateur, fournisseur, admin }

// Provider pour obtenir le rôle de l'utilisateur connecté
final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final authService = AuthService();
  final role = await authService.getUserRole();
  return _parseRole(role ?? 'client');
});

// Fonction pour parser le rôle depuis une string
UserRole _parseRole(String role) {
  switch (role.toLowerCase()) {
    case 'restaurateur':
      return UserRole.restaurateur;
    case 'fournisseur':
      return UserRole.fournisseur;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.client;
  }
}

// Provider pour les destinations de navigation
final navigationDestinationsProvider = FutureProvider<List<NavigationDestination>>((ref) async {
  final userRoleAsync = ref.watch(userRoleProvider);
  
  return userRoleAsync.when(
    data: (role) => _buildDestinations(role),
    loading: () => _buildDestinations(UserRole.client), // Par défaut
    error: (error, stack) => _buildDestinations(UserRole.client), // En cas d'erreur
  );
});

// Provider pour les routes de navigation
final navigationRoutesProvider = FutureProvider<List<String>>((ref) async {
  final userRoleAsync = ref.watch(userRoleProvider);
  
  return userRoleAsync.when(
    data: (role) => _buildRoutes(role),
    loading: () => _buildRoutes(UserRole.client), // Par défaut
    error: (error, stack) => _buildRoutes(UserRole.client), // En cas d'erreur
  );
});

List<NavigationDestination> _buildDestinations(UserRole role) {
  // Destinations de base pour tous les utilisateurs
  final baseDestinations = <NavigationDestination>[
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
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: 'Événements',
    ),
    const NavigationDestination(
      icon: Icon(Icons.room_service_outlined),
      selectedIcon: Icon(Icons.room_service),
      label: 'Services',
    ),
    const NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: 'Restaurants',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  // Construire la liste finale selon le rôle
  switch (role) {
    case UserRole.client:
      return baseDestinations;
    
    case UserRole.restaurateur:
    case UserRole.fournisseur:
      return [
        ...baseDestinations,
        const NavigationDestination(
          icon: Icon(Icons.home),
          selectedIcon: Icon(Icons.home),
          label: 'Tableau de Bord',
        ),
      ];
    
    case UserRole.admin:
      return [
        ...baseDestinations,
        const NavigationDestination(
          icon: Icon(Icons.home),
          selectedIcon: Icon(Icons.home),
          label: 'Tableau de Bord',
        ),
        const NavigationDestination(
          icon: Icon(Icons.star),
          selectedIcon: Icon(Icons.star),
          label: 'Admin',
        ),
      ];
    
    default:
      return baseDestinations;
  }
}

List<String> _buildRoutes(UserRole role) {
  final routes = <String>[
    '/',
    '/menus',
    '/evenements',
    '/services',
    '/restaurants',
    '/profil',
  ];

  // Ajouter le tableau de bord pour les rôles avec permissions
  if (role != UserRole.client) {
    routes.add('/dashboard');
  }

  // Ajouter la route admin uniquement pour les administrateurs
  if (role == UserRole.admin) {
    routes.add('/admin');
  }

  return routes;
}
