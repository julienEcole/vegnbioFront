import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/view_factory_wrapper.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ViewFactoryWrapper(
      pageType: 'events',
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