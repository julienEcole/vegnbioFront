import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/auth_guard_wrapper.dart';
import '../widgets/public_events_view.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEventsScreen(context).authGuard(
      pageType: 'public', // Les événements sont publics mais peuvent avoir des fonctionnalités admin
      publicView: const PublicEventsView(), // Vue publique si token invalide
      requireAuth: false, // Pas d'authentification requise pour voir les événements
      customMessage: 'Connectez-vous pour accéder aux fonctionnalités complètes',
    );
  }

  Widget _buildEventsScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout d'événement (pour les administrateurs)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implémenter l'ajout d'événement
            },
            icon: const Icon(Icons.add),
            label: const Text('📅 Ajouter un événement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Page des événements à venir',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Fonctionnalités d\'administration disponibles',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}