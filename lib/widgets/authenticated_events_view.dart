import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Vue authentifiée pour les événements - accessible aux utilisateurs connectés
class AuthenticatedEventsView extends ConsumerWidget {
  const AuthenticatedEventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout d'événement (pour les administrateurs)
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              if (authState is AuthenticatedAuthState && 
                  ['admin', 'restaurateur', 'fournisseur'].contains(authState.role)) {
                return ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'ajout d'événement
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('📅 Ajouter un événement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Événements',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Découvrez nos événements spéciaux',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            Text(
              'Fonctionnalité en cours de développement...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
