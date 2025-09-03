import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/navigation_bar.dart';
import '../services/navigation_service.dart';

/// Vue publique des services accessible sans authentification
class PublicServicesView extends ConsumerWidget {
  const PublicServicesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services - Vue Publique'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final navigationService = NavigationService();
              await navigationService.navigateToLogin(context);
            },
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message informatif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vue publique des services',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connectez-vous pour accéder aux fonctionnalités complètes',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenu des services
          Expanded(
            child: _buildServicesContent(context),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _buildServicesContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.room_service,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nos Services',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez tous les services que nous proposons',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Services disponibles
          _buildServiceCard(
            context,
            'Livraison à domicile',
            'Commandez vos plats bio préférés et recevez-les chez vous.',
            Icons.delivery_dining,
            Colors.green,
            'Disponible 7j/7',
          ),
          const SizedBox(height: 16),
          _buildServiceCard(
            context,
            'Réservation de table',
            'Réservez votre table dans nos restaurants pour une expérience optimale.',
            Icons.table_restaurant,
            Colors.blue,
            'Réservation en ligne',
          ),
          const SizedBox(height: 16),
          _buildServiceCard(
            context,
            'Catering événementiel',
            'Organisez vos événements avec notre service de traiteur bio.',
            Icons.event_seat,
            Colors.orange,
            'Sur devis',
          ),
          const SizedBox(height: 16),
          _buildServiceCard(
            context,
            'Formation cuisine',
            'Apprenez à cuisiner bio avec nos chefs expérimentés.',
            Icons.school,
            Colors.purple,
            'Cours disponibles',
          ),
          const SizedBox(height: 16),
          _buildServiceCard(
            context,
            'Consultation nutrition',
            'Bénéficiez de conseils nutritionnels personnalisés.',
            Icons.health_and_safety,
            Colors.teal,
            'Avec nos diététiciens',
          ),
          const SizedBox(height: 16),
          _buildServiceCard(
            context,
            'Abonnement mensuel',
            'Recevez chaque mois une sélection de nos meilleurs plats.',
            Icons.subscriptions,
            Colors.red,
            'Formule avantageuse',
          ),
          const SizedBox(height: 32),
          
          // Call to action
          Center(
            child: Column(
              children: [
                Text(
                  'Intéressé par nos services ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final navigationService = NavigationService();
                    await navigationService.navigateToLogin(context);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter pour en savoir plus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String badge,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
