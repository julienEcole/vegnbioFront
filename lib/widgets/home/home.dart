import 'package:flutter/material.dart';

/// Vue publique de la page d'accueil
class PublicHomeView extends StatelessWidget {
  const PublicHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenir la taille de l'écran
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VegnBio'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos de VegnBio',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VegnBio est votre magasin bio de confiance, proposant une large gamme de produits biologiques et locaux.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Nos Horaires',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildHoraireCard(context, isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoraireCard(BuildContext context, bool isSmallScreen) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          children: const [
            _HoraireRow(jour: 'Lundi', horaires: '9h00 - 19h00'),
            _HoraireRow(jour: 'Mardi', horaires: '9h00 - 19h00'),
            _HoraireRow(jour: 'Mercredi', horaires: '9h00 - 19h00'),
            _HoraireRow(jour: 'Jeudi', horaires: '9h00 - 19h00'),
            _HoraireRow(jour: 'Vendredi', horaires: '9h00 - 19h00'),
            _HoraireRow(jour: 'Samedi', horaires: '9h00 - 18h00'),
            _HoraireRow(jour: 'Dimanche', horaires: 'Fermé'),
          ],
        ),
      ),
    );
  }
}

class _HoraireRow extends StatelessWidget {
  final String jour;
  final String horaires;

  const _HoraireRow({
    required this.jour,
    required this.horaires,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            jour,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            horaires,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
