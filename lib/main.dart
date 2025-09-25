import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'factories/auth_view_factory.dart';
import 'factories/dashboard_view_factory.dart';
import 'factories/event_view_factory.dart';
import 'factories/restaurant_view_factory.dart';
import 'factories/menu_view_factory.dart';
import 'factories/service_view_factory.dart';
import 'widgets/main_layout.dart';

void main() {
  print('🚀 MAIN START');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏗️ MYAPP BUILD');

    return MaterialApp.router(
      title: 'Veg\'N Bio',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  // Note: La logique de navigation et d'authentification est maintenant centralisée
  // dans CustomNavigationBar pour une meilleure gestion globale
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MainLayout(
        currentRoute: '/',
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/profil',
      builder: (context, state) {
        final viewType = state.uri.queryParameters['view'];
        return MainLayout(
          currentRoute: '/profil',
          child: Consumer(
            builder: (context, ref, child) {
              return AuthViewFactory.createAuthView(
                ref,
                forcedType: viewType != null 
                  ? AuthViewType.values.firstWhere(
                      (e) => e.name == viewType,
                      orElse: () => AuthViewType.defaultView,
                    )
                  : null,
              );
            },
          ),
        );
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => MainLayout(
        currentRoute: '/dashboard',
        child: Consumer(
          builder: (context, ref, child) {
            return DashboardViewFactory.createDashboardView(ref);
          },
        ),
      ),
    ),
    GoRoute(
      path: '/evenements',
      builder: (context, state) => MainLayout(
        currentRoute: '/evenements',
        child: Consumer(
          builder: (context, ref, child) {
            return EventViewFactory.createEventView(ref);
          },
        ),
      ),
    ),
    GoRoute(
      path: '/restaurants',
      builder: (context, state) => MainLayout(
        currentRoute: '/restaurants',
        child: Consumer(
          builder: (context, ref, child) {
            return RestaurantViewFactory.createRestaurantView(ref);
          },
        ),
      ),
    ),
    GoRoute(
      path: '/menus',
      builder: (context, state) => MainLayout(
        currentRoute: '/menus',
        child: Consumer(
          builder: (context, ref, child) {
            return MenuViewFactory.createMenuView(ref);
          },
        ),
      ),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => MainLayout(
        currentRoute: '/services',
        child: Consumer(
          builder: (context, ref, child) {
            return ServiceViewFactory.createServiceView(ref);
          },
        ),
      ),
    ),
    GoRoute(
      path: '/panier',
      builder: (context, state) => MainLayout(
        currentRoute: '/panier',
        child: const CartPage(),
      ),
    ),
    GoRoute(
      path: '/commandes',
      builder: (context, state) => MainLayout(
        currentRoute: '/commandes',
        child: const OrdersScreen(),
      ),
    ),
  ],
);