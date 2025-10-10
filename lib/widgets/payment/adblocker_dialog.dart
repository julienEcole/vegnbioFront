import 'package:flutter/material.dart';

/// Dialog informatif pour les problèmes d'AdBlocker avec Stripe
class AdBlockerDialog extends StatelessWidget {
  const AdBlockerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AdBlockerDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.block,
            color: Colors.orange.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bloqueur de publicités détecté',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre bloqueur de publicités empêche le traitement sécurisé des paiements.',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pourquoi désactiver temporairement ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stripe utilise des domaines qui peuvent être bloqués par les bloqueurs de publicités. Ces domaines sont nécessaires pour le traitement sécurisé des paiements.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Solutions recommandées :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildSolutionItem(
              icon: Icons.pause_circle_outline,
              title: 'Désactiver temporairement',
              description: 'Cliquez sur l\'icône de votre bloqueur et désactivez-le pour cette page',
            ),
            
            const SizedBox(height: 8),
            
            _buildSolutionItem(
              icon: Icons.add_circle_outline,
              title: 'Ajouter des exceptions',
              description: 'Autorisez *.stripe.com et *.js.stripe.com dans votre bloqueur',
            ),
            
            const SizedBox(height: 8),
            
            _buildSolutionItem(
              icon: Icons.visibility_off,
              title: 'Mode navigation privée',
              description: 'Ouvrez cette page dans une fenêtre de navigation privée',
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vos données de carte sont toujours sécurisées par Stripe',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF387D35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Compris',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Optionnel : ouvrir une nouvelle fenêtre en mode incognito
            _openIncognitoWindow();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Mode privé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSolutionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openIncognitoWindow() {
    // Cette fonction pourrait ouvrir une nouvelle fenêtre en mode incognito
    // Pour l'instant, on affiche juste un message
    print('💡 Conseil : Ouvrez cette page dans une fenêtre de navigation privée');
  }
}
