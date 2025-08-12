import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/events_screen.dart';
import 'screens/services_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/profile_screen.dart';
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
  ],
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