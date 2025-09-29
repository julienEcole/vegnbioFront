import 'package:flutter/material.dart';
import '../widgets/payment/unified_payment_modal.dart';
import '../services/payement/unified_payment_service.dart';

/// Exemple d'utilisation du système de paiement unifié
class PaymentExampleScreen extends StatefulWidget {
  const PaymentExampleScreen({super.key});

  @override
  State<PaymentExampleScreen> createState() => _PaymentExampleScreenState();
}

class _PaymentExampleScreenState extends State<PaymentExampleScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      await UnifiedPaymentService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du paiement: $e');
    }
  }

  Future<void> _showPaymentModal() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initialisation du paiement en cours...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await UnifiedPaymentModal.showPaymentModal(
      context: context,
      amount: 25.50,
      currency: 'eur',
      description: 'Commande Veg\'N Bio - Menu du jour',
    );

    if (result != null) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement réussi ! Montant: ${result.amountInEuros?.toStringAsFixed(2)} €'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple de Paiement'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut d'initialisation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isInitialized ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isInitialized ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isInitialized ? Icons.check_circle : Icons.hourglass_empty,
                    color: _isInitialized ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isInitialized 
                        ? 'Système de paiement initialisé' 
                        : 'Initialisation en cours...',
                    style: TextStyle(
                      color: _isInitialized ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informations de la commande
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Récapitulatif de la commande',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOrderItem('Menu du jour', 'Salade bio, soupe, dessert', 12.50),
                    _buildOrderItem('Boisson', 'Jus de fruits frais', 3.50),
                    _buildOrderItem('Livraison', 'Frais de livraison', 2.00),
                    const Divider(),
                    _buildOrderItem('Total', '', 18.00, isTotal: true),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de paiement
            ElevatedButton(
              onPressed: _isInitialized ? _showPaymentModal : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Payer maintenant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations sur les cartes de test
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
                  Text(
                    '💳 Cartes de test disponibles:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Visa: 4242 4242 4242 4242\n• Mastercard: 5555 5555 5555 4444\n• American Express: 3782 822463 10005\n• CVV: n\'importe quel code 3-4 chiffres\n• Date: n\'importe quelle date future',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
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

  Widget _buildOrderItem(String name, String description, double price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    fontSize: isTotal ? 16 : 14,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${price.toStringAsFixed(2)} €',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
