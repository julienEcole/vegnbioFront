import 'package:flutter/material.dart';

class PanierSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const PanierSummaryWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la commande',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Nombre d'articles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Articles (${stats['nombreArticles']})'),
                Text('${stats['nombreItems']} types'),
              ],
            ),
            
            const Divider(),
            
            // Détail des prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total HT'),
                Text('${stats['totalHT'].toStringAsFixed(2)} €'),
              ],
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TVA (${stats['tauxTVA']}%)'),
                Text('${stats['montantTVA'].toStringAsFixed(2)} €'),
              ],
            ),
            
            const Divider(),
            
            // Total TTC
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total TTC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${stats['totalTTC'].toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
