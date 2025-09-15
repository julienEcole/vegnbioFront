import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏠 [HomeScreen] BUILD APPELÉ !');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veg\'N Bio'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profil'),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Bienvenue sur Veg\'N Bio !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('L\'application fonctionne correctement'),
            SizedBox(height: 32),
            Text(
              'Navigation disponible :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _NavigationButton(
                  label: 'Dashboard',
                  icon: Icons.dashboard,
                  route: '/dashboard',
                ),
                _NavigationButton(
                  label: 'Événements',
                  icon: Icons.event,
                  route: '/evenements',
                ),
                _NavigationButton(
                  label: 'Restaurants',
                  icon: Icons.restaurant,
                  route: '/restaurants',
                ),
                _NavigationButton(
                  label: 'Menus',
                  icon: Icons.menu_book,
                  route: '/menus',
                ),
                _NavigationButton(
                  label: 'Services',
                  icon: Icons.room_service,
                  route: '/services',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _NavigationButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.go(route),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}