import 'package:flutter/material.dart';
import 'payment_form_widget.dart';
import '../../services/payment_service.dart';

class PaymentModal extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final Function(PaymentResult) onPaymentResult;

  const PaymentModal({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onPaymentResult,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();

  static Future<PaymentResult?> showPaymentModal({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
  }) async {
    PaymentResult? result;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentModal(
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

class _PaymentModalState extends State<PaymentModal> {
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
                color: Theme.of(context).colorScheme.primary,
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
                          'Paiement',
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
                child: PaymentFormWidget(
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
