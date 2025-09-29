import 'package:flutter/material.dart';
import '../../factories/payment_form_factory.dart';
import '../../services/payement/unified_payment_service.dart';

/// Modal de paiement unifié utilisant la factory
class UnifiedPaymentModal extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final Function(StripePaymentResult) onPaymentResult;

  const UnifiedPaymentModal({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onPaymentResult,
  });

  @override
  State<UnifiedPaymentModal> createState() => _UnifiedPaymentModalState();

  /// Méthode statique pour afficher le modal de paiement
  static Future<StripePaymentResult?> showPaymentModal({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
  }) async {
    StripePaymentResult? result;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnifiedPaymentModal(
        amount: amount,
        currency: currency,
        description: description,
        onPaymentResult: (paymentResult) {
          result = paymentResult;
        },
      ),
    );

    return result;
  }
}

class _UnifiedPaymentModalState extends State<UnifiedPaymentModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête du modal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paiement sécurisé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Commande Veg\'N Bio',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu du formulaire de paiement
            Flexible(
              child: SingleChildScrollView(
                child: PaymentFormFactory.createPaymentForm(
                  amount: widget.amount,
                  currency: widget.currency,
                  description: widget.description,
                  onPaymentResult: (result) {
                    Navigator.of(context).pop();
                    widget.onPaymentResult(result);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
