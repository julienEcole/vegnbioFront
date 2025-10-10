// lib/widgets/navigation/responsive_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vegnbio_front/providers/auth_provider.dart';

/// Point de rupture pour passer de mobile à desktop
const double kDesktopBreakpoint = 900.0;

/// Modèle pour les destinations de navigation
class NavDestination {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final List<String> requiredRoles;

  const NavDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.requiredRoles = const [],
  });
}

/// Liste des destinations de navigation
class NavigationDestinations {
  static const List<NavDestination> destinations = [
    NavDestination(
      route: '/',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Accueil',
    ),
    NavDestination(
      route: '/restaurants',
      icon: Icons.store_mall_directory_outlined,
      selectedIcon: Icons.store_mall_directory,
      label: 'Restaurants',
    ),
    NavDestination(
      route: '/evenements',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      label: 'Événements',
    ),
    // Place de marché (restaurateur)
    NavDestination(
      route: '/market',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Place de marché',
      requiredRoles: ['restaurateur'],
    ),
    // Gestion des événements (restaurateur/admin)
    NavDestination(
      route: '/evenements-gestions',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
      label: 'Gestion des événements',
      requiredRoles: ['restaurateur', 'admin'],
    ),
    // Offres fournisseur (fournisseur)
    NavDestination(
      route: '/mes-offres',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Mes offres',
      requiredRoles: ['fournisseur'],
    ),
    // ❌ Dashboard retiré
    // NavDestination(
    //   route: '/dashboard',
    //   icon: Icons.dashboard_outlined,
    //   selectedIcon: Icons.dashboard,
    //   label: 'Dashboard',
    //   requiredRoles: ['restaurateur', 'admin', 'fournisseur'],
    // ),
    // Commandes (client/restaurateur/admin)
    NavDestination(
      route: '/commandes',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      label: 'Commandes',
      requiredRoles: ['client', 'restaurateur', 'admin'],
    ),
    // Admin — reports
    NavDestination(
      route: '/admin/reports',
      icon: Icons.report_outlined,
      selectedIcon: Icons.report,
      label: 'Signalements',
      requiredRoles: ['admin'],
    ),
    // Profil (tout le monde)
    NavDestination(
      route: '/profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  /// Filtre les destinations selon les permissions utilisateur
  static List<NavDestination> getVisibleDestinations(AuthState authState) {
    return destinations.where((dest) {
      if (dest.requiredRoles.isEmpty) return true; // public
      if (!authState.isAuthenticated) return false;
      final userRole = authState.role?.toLowerCase();
      return userRole != null && dest.requiredRoles.contains(userRole);
    }).toList();
  }
}

/// Navigation Bar responsive (bottom bar mobile / sidebar desktop)
class ResponsiveNavigationBar extends ConsumerWidget {
  final String currentRoute;

  const ResponsiveNavigationBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDesktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;

    if (isDesktop) {
      return const SizedBox.shrink(); // Le sidebar est géré dans MainLayout
    }

    return _buildBottomNavigationBar(context, ref, authState);
  }

  Widget _buildBottomNavigationBar(
      BuildContext context,
      WidgetRef ref,
      AuthState authState,
      ) {
    final visibleDestinations =
    NavigationDestinations.getVisibleDestinations(authState);
    final currentIndex = _getCurrentIndex(visibleDestinations);

    return NavigationBar(
      backgroundColor: const Color(0xFF387D35),
      indicatorColor: Colors.white,
      elevation: 8,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) =>
          _handleNavigation(context, ref, visibleDestinations[index].route),
      destinations: visibleDestinations.map((dest) {
        return NavigationDestination(
          icon: Icon(dest.icon, color: Colors.white),
          selectedIcon: Icon(dest.selectedIcon, color: Colors.green),
          label: dest.label,
        );
      }).toList(),
    );
  }

  int _getCurrentIndex(List<NavDestination> destinations) {
    final index = destinations.indexWhere((dest) => dest.route == currentRoute);
    return index >= 0 ? index : 0;
  }

  void _handleNavigation(BuildContext context, WidgetRef ref, String route) {
    context.go(route);
  }
}

/// Sidebar de navigation pour desktop
class NavigationSidebar extends ConsumerWidget {
  final String currentRoute;

  const NavigationSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final visibleDestinations =
    NavigationDestinations.getVisibleDestinations(authState);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF387D35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.green.shade800,
            child: Column(
              children: [
                const Icon(Icons.eco, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Veg\'N Bio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (authState.isAuthenticated && authState.userData != null)
                  Text(
                    authState.userData!['email'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Liste de navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: visibleDestinations.map((dest) {
                final isSelected = dest.route == currentRoute;
                return _buildNavTile(context, ref, dest, isSelected);
              }).toList(),
            ),
          ),

          // Footer avec bouton de déconnexion si connecté
          if (authState.isAuthenticated)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                onTap: () => _handleLogout(ref),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavTile(
      BuildContext context,
      WidgetRef ref,
      NavDestination dest,
      bool isSelected,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? dest.selectedIcon : dest.icon,
          color: Colors.white,
        ),
        title: Text(
          dest.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => context.go(dest.route),
      ),
    );
  }

  void _handleLogout(WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
  }
}
