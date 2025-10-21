import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/app_config.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/privacy/privacy_policy_screen.dart';
import 'screens/privacy/account_deletion_screen.dart';
import 'screens/privacy/data_deletion_info_screen.dart';
import 'factories/auth_view_factory.dart';
import 'factories/dashboard_view_factory.dart';
import 'factories/event_view_factory.dart';
import 'factories/restaurant_view_factory.dart';
import 'factories/menu_view_factory.dart';
import 'factories/service_view_factory.dart';
import 'screens/events/events_admin_dashboard.dart';
import 'screens/offres/mes_offres_screen.dart';
import 'factories/commande_view_factory.dart';
import 'widgets/main_layout.dart';
import 'providers/auth_provider.dart';
import 'services/auth/real_auth_service.dart';
import 'screens/restaurant/restaurant_menus_screen.dart';
import 'screens/offres/marketplace_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vegnbio_front/widgets/reports_admin_screen.dart';

void main() async {
  // print('🚀 MAIN START');
  
  // Charger les variables d'environnement
  await AppConfig.loadEnv();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // print('🏗️ MYAPP BUILD');

    return MaterialApp.router(
      title: 'Veg\'N Bio',
      // ✅ Localisation (FR/EN) pour DatePicker/TimePicker & widgets Material
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('fr'),

      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // ton router existant
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
      path: '/restaurants/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.tryParse(idStr) ?? 0;

        // on récupère le nom passé en extra si dispo
        final name = (state.extra is Map && (state.extra as Map).containsKey('name'))
            ? (state.extra as Map)['name'] as String
            : 'Restaurant';

        return MainLayout(
          currentRoute: '/restaurants',
          child: RestaurantMenusScreen(
            restaurantId: id,
            restaurantName: name,
          ),
        );
      },
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
      path: '/evenements-gestions',
      builder: (context, state) => MainLayout(
        currentRoute: '/evenements-gestions',
        child: Consumer(
          builder: (context, ref, child) {
            return const EventAdminDashboard();
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
        child: Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);

            if (!authState.isAuthenticated || authState.userData == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Mes commandes'),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                body: const Center(
                  child: Text('Connexion requise pour voir les commandes'),
                ),
              );
            }

            final authService = RealAuthService();
            final role = authState.role ?? 'client';
            final userId = authState.userData!['id'] as int;
            final token = authService.token;

            return CommandeViewFactory.createCommandeView(
              userRole: role,
              userId: userId,
              restaurantId: null, // TODO: à implémenter pour les restaurateurs
              token: token,
            );
          },
        ),
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/data-deletion-info',
      builder: (context, state) => const DataDeletionInfoScreen(),
    ),
    GoRoute(
      path: '/account-deletion',
      builder: (context, state) => MainLayout(
        currentRoute: '/account-deletion',
        child: const AccountDeletionScreen(),
      ),
    ),
    GoRoute(
      path: '/mes-offres',
      builder: (context, state) => MainLayout(
        currentRoute: '/mes-offres',
        child: const MesOffresScreen(),
      ),
    ),
    GoRoute(
      path: '/market',
      builder: (context, state) => MainLayout(
        currentRoute: '/market',
        child: const RestaurateurMarketplaceScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => MainLayout(
        currentRoute: '/admin/reports',
        child: const ReportsAdminScreen(),
      ),
    ),
  ],
);