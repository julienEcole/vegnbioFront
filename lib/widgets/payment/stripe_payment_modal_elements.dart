import 'package:flutter/material.dart';
import '../../services/stripe_service.dart';
import 'stripe_unified_form.dart';

class StripePaymentModalElements {
  static Future<StripePaymentResult?> showPaymentModal({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
  }) async {
    StripePaymentIntent? paymentIntent;
    
    try {
      // Créer le PaymentIntent
      paymentIntent = await StripeService.createPaymentIntent(
        amount: (amount * 100).toDouble(), // Convertir en centimes
        currency: currency.toLowerCase(),
        description: description,
      );
      
      print('✅ [StripePaymentModalElements] PaymentIntent créé: ${paymentIntent.paymentIntentId}');
    } catch (e) {
      print('❌ [StripePaymentModalElements] Erreur lors de la création du PaymentIntent: $e');
      return StripePaymentResult(
        success: false,
        error: 'Erreur lors de la création du PaymentIntent: $e',
      );
    }

    // Afficher le modal de paiement
    final result = await showDialog<StripePaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paiement sécurisé',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(
                        StripePaymentResult(
                          success: false,
                          error: 'Paiement annulé par l\'utilisateur',
                        ),
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Informations de la commande
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Récapitulatif de la commande',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Description: $description'),
                      Text('Montant: ${amount.toStringAsFixed(2)} $currency'),
                      Text('Devise: ${currency.toUpperCase()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Formulaire de paiement
                Expanded(
                  child: SingleChildScrollView(
                    child: StripeUnifiedForm(
                      showClassicFields: true, // Afficher les champs classiques par défaut
                      onPaymentSuccess: (paymentMethodId) async {
                        try {
                          print('🔄 [StripePaymentModalElements] Confirmation du paiement...');
                          
                          // Confirmer le PaymentIntent
                          final confirmedIntent = await StripeService.confirmPaymentIntent(
                            paymentIntentId: paymentIntent!.paymentIntentId,
                            paymentMethodId: paymentMethodId,
                          );
                          
                          print('✅ [StripePaymentModalElements] Paiement confirmé: ${confirmedIntent.status}');
                          
                          Navigator.of(context).pop(
                            StripePaymentResult(
                              success: true,
                              paymentIntentId: confirmedIntent.paymentIntentId,
                              status: confirmedIntent.status,
                            ),
                          );
                        } catch (e) {
                          print('❌ [StripePaymentModalElements] Erreur lors de la confirmation: $e');
                          Navigator.of(context).pop(
                            StripePaymentResult(
                              success: false,
                              error: 'Erreur lors de la confirmation du paiement: $e',
                            ),
                          );
                        }
                      },
                      onPaymentError: (error) {
                        Navigator.of(context).pop(
                          StripePaymentResult(
                            success: false,
                            error: error,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Retourner le résultat
    if (result != null) {
      return result;
    } else {
      return StripePaymentResult(
        success: false,
        error: 'Paiement annulé',
      );
    }
  }
}
