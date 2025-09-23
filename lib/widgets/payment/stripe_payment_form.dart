import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/stripe_service.dart';
import '../../factories/stripe_factory.dart';

class StripePaymentForm extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final Function(StripePaymentResult) onPaymentResult;

  const StripePaymentForm({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onPaymentResult,
  });

  @override
  State<StripePaymentForm> createState() => _StripePaymentFormState();
}

class _StripePaymentFormState extends State<StripePaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  bool _isProcessing = false;
  StripePaymentIntent? _paymentIntent;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
    _createPaymentIntent();
  }

  Future<void> _initializeStripe() async {
    try {
      await StripeFactory.initialize();
    } catch (e) {
      print('❌ [StripePaymentForm] Erreur lors de l\'initialisation de Stripe: $e');
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _createPaymentIntent() async {
    try {
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: widget.amount,
        currency: widget.currency,
        description: widget.description,
        metadata: {
          'source': 'vegnbio_app',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      setState(() {
        _paymentIntent = paymentIntent;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation du paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du paiement
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paiement sécurisé Stripe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.amount.toStringAsFixed(2)} ${widget.currency.toUpperCase()}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Numéro de carte
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Numéro de carte',
                hintText: '1234 5678 9012 3456',
                prefixIcon: const Icon(Icons.credit_card),
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  _getCardIcon(_cardNumberController.text),
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir le numéro de carte';
                }
                if (value.replaceAll(RegExp(r'\s'), '').length != 16) {
                  return 'Le numéro de carte doit contenir 16 chiffres';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Pour mettre à jour l'icône de carte
              },
            ),

            const SizedBox(height: 16),

            // Date d'expiration et CVV
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'MM/AA',
                      hintText: '12/25',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date requise';
                      }
                      if (value.length != 5) {
                        return 'Format MM/AA';
                      }
                      
                      // Validation de la date
                      final parts = value.split('/');
                      if (parts.length != 2) return 'Format invalide';
                      
                      final month = int.tryParse(parts[0]);
                      final year = int.tryParse(parts[1]);
                      
                      if (month == null || year == null) return 'Format invalide';
                      if (month < 1 || month > 12) return 'Mois invalide';
                      
                      final now = DateTime.now();
                      final expYear = 2000 + year;
                      final expDate = DateTime(expYear, month);
                      
                      if (expDate.isBefore(now)) return 'Carte expirée';
                      
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: Icon(Icons.security),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CVV requis';
                      }
                      if (value.length < 3) {
                        return 'CVV invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nom du titulaire
            TextFormField(
              controller: _cardholderNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du titulaire',
                hintText: 'Jean Dupont',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nom du titulaire requis';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Payer maintenant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Note de sécurité
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
                    Icons.security,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé par Stripe. Vos informations de carte sont chiffrées et ne sont jamais stockées.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Informations de test
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💳 Cartes de test Stripe:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Visa: 4242 4242 4242 4242\n• Mastercard: 5555 5555 5555 4444\n• CVV: n\'importe quel code 3-4 chiffres\n• Date: n\'importe quelle date future',
                    style: TextStyle(
                      fontSize: 11,
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


  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentIntent == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Étape 1: Créer un PaymentMethod selon la plateforme
      final paymentMethodId = await _createPaymentMethod();
      
      // Étape 2: Confirmer le PaymentIntent avec le PaymentMethod
      final result = await StripeService.confirmPaymentIntent(
        paymentIntentId: _paymentIntent!.paymentIntentId,
        paymentMethodId: paymentMethodId,
      );
      
      widget.onPaymentResult(result);
    } catch (e) {
      print('❌ [StripePaymentForm] Erreur lors du paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String> _createPaymentMethod() async {
    try {
      // Utiliser la factory pour créer le PaymentMethod selon la plateforme
      return await StripeFactory.createPaymentMethod(
        cardNumber: _cardNumberController.text.replaceAll(RegExp(r'\s'), ''),
        expMonth: int.parse(_expiryDateController.text.split('/')[0]),
        expYear: int.parse(_expiryDateController.text.split('/')[1]),
        cvc: _cvvController.text,
        cardholderName: _cardholderNameController.text.trim(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du PaymentMethod: $e');
    }
  }

  IconData _getCardIcon(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s'), '');
    
    if (cleanNumber.startsWith('4')) {
      return Icons.credit_card; // Visa
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return Icons.credit_card; // Mastercard
    } else if (cleanNumber.startsWith('3')) {
      return Icons.credit_card; // American Express
    }
    
    return Icons.credit_card;
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final formatted = _formatCardNumber(text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCardNumber(String text) {
    final cleanText = text.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanText[i]);
    }
    return buffer.toString();
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}

