import 'package:flutter/material.dart';
import 'stripe_payment_form.dart';
import '../../services/stripe_service.dart';

class StripePaymentModal extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final Function(StripePaymentResult) onPaymentResult;

  const StripePaymentModal({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onPaymentResult,
  });

  @override
  State<StripePaymentModal> createState() => _StripePaymentModalState();

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
      builder: (context) => StripePaymentModal(
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

class _StripePaymentModalState extends State<StripePaymentModal> {
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
                          'Paiement Stripe',
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
                child: StripePaymentForm(
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
