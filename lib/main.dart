import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/events_screen.dart';
import 'screens/services_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_menu_screen.dart';
import 'screens/admin_restaurant_screen.dart';
import 'screens/edit_menu_screen.dart';
import 'screens/edit_restaurant_screen.dart';
import 'providers/menu_provider.dart';
import 'providers/restaurant_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/menus',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/menus/restaurant/:restaurantId',
      builder: (context, state) {
        final restaurantId = int.tryParse(state.pathParameters['restaurantId'] ?? '');
        return MenuScreen(restaurantId: restaurantId);
      },
    ),
    GoRoute(
      path: '/evenements',
      builder: (context, state) => const EventsScreen(),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => const ServicesScreen(),
    ),
    GoRoute(
      path: '/restaurants',
      builder: (context, state) => const RestaurantsScreen(),
    ),
    GoRoute(
      path: '/restaurants/:restaurantId',
      builder: (context, state) {
        final restaurantId = int.tryParse(state.pathParameters['restaurantId'] ?? '');
        return RestaurantsScreen(highlightRestaurantId: restaurantId);
      },
    ),
    GoRoute(
      path: '/profil',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    // Routes admin pour la création
    GoRoute(
      path: '/admin/menu/new',
      builder: (context, state) => const AdminMenuScreen(),
    ),
    GoRoute(
      path: '/admin/restaurant/new',
      builder: (context, state) => const AdminRestaurantScreen(),
    ),
    // Routes pour l'édition
    GoRoute(
      path: '/admin/menu/edit/:id',
      builder: (context, state) {
        final menuId = int.tryParse(state.pathParameters['id'] ?? '');
        if (menuId == null) {
          return const Scaffold(body: Center(child: Text('ID de menu invalide')));
        }
        return Consumer(
          builder: (context, ref, child) {
            final menuAsync = ref.watch(menuProvider(menuId));
            
            return menuAsync.when(
              data: (menu) => EditMenuScreen(menu: menu),
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Scaffold(
                body: Center(child: Text('Erreur: $error')),
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/admin/restaurant/edit/:id',
      builder: (context, state) {
        final restaurantId = int.tryParse(state.pathParameters['id'] ?? '');
        if (restaurantId == null) {
          return const Scaffold(body: Center(child: Text('ID de restaurant invalide')));
        }
        return Consumer(
          builder: (context, ref, child) {
            final restaurantAsync = ref.watch(restaurantProvider(restaurantId));
            
            return restaurantAsync.when(
              data: (restaurant) => EditRestaurantScreen(restaurant: restaurant),
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Scaffold(
                body: Center(child: Text('Erreur: $error')),
              ),
            );
          },
        );
      },
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(
      child: Text('Page non trouvée'),
    ),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Veg'N Bio",
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,  // Supprime la bannière debug
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}