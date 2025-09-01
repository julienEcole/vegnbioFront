import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/navigation_provider.dart';

class CustomNavigationBar extends ConsumerWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentLocation = GoRouterState.of(context).uri.path;

    final destinationsAsync = ref.watch(navigationDestinationsProvider);
    final routesAsync = ref.watch(navigationRoutesProvider);

    return destinationsAsync.when(
      data: (destinations) {
        final selectedIndex = _getSelectedIndex(currentLocation, ref);
        return NavigationBar(
          backgroundColor: Colors.green,
          indicatorColor: Colors.white,
          elevation: 8,
          destinations: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            routesAsync.when(
              data: (routes) {
                if (index < routes.length) {
                  context.go(routes[index]);
                }
              },
              loading: () {},
              error: (error, stack) {},
            );
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        );
      },
      loading: () => NavigationBar(
        backgroundColor: Colors.green,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Chargement...',
          ),
        ],
      ),
      error: (error, stack) => NavigationBar(
        backgroundColor: Colors.green,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.error_outline),
            label: 'Erreur',
          ),
        ],
      ),
    );
  }

  // Retourne l'index en fonction de la route actuelle (gère aussi les sous-routes)
  int _getSelectedIndex(String location, WidgetRef ref) {
    final routesAsync = ref.watch(navigationRoutesProvider);
    return routesAsync.when(
      data: (routes) {
        int bestIndex = 0;
        int bestLength = -1;
        for (int i = 0; i < routes.length; i++) {
          final route = routes[i];
          if (location == route || location.startsWith('$route/')) {
            if (route.length > bestLength) {
              bestIndex = i;
              bestLength = route.length;
            }
          }
        }
        return bestIndex;
      },
      loading: () => 0,
      error: (error, stack) => 0,
    );
  }
}