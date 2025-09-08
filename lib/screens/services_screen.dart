import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/view_factory_wrapper.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ViewFactoryWrapper(
      pageType: 'services',
    );
  }

  Widget _buildServicesScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Services'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Bouton d'ajout de service (pour les administrateurs)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implémenter l'ajout de service
            },
            icon: const Icon(Icons.add),
            label: const Text('⚙️ Ajouter un service'),
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
            Icon(Icons.room_service, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Page des services à venir',
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