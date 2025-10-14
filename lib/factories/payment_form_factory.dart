import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payement/unified_payment_service.dart';

/// Types de cartes supportés par Stripe
enum StripeCardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unionpay,
  unknown,
}

/// Factory pour créer les formulaires de paiement selon le type de carte
class PaymentFormFactory {
  /// Créer un formulaire de paiement adapté au type de carte détecté
  static Widget createPaymentForm({
    required double amount,
    required String currency,
    required String description,
    required Function(StripePaymentResult) onPaymentResult,
    StripeCardType? preferredCardType,
  }) {
    return UnifiedPaymentForm(
      amount: amount,
      currency: currency,
      description: description,
      onPaymentResult: onPaymentResult,
      preferredCardType: preferredCardType,
    );
  }

  /// Détecter le type de carte à partir du numéro
  static StripeCardType detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\s'), '');
    
    if (cleanNumber.isEmpty) return StripeCardType.unknown;
    
    // Visa
    if (RegExp(r'^4').hasMatch(cleanNumber)) {
      return StripeCardType.visa;
    }
    
    // Mastercard
    if (RegExp(r'^5[1-5]|^2[2-7]').hasMatch(cleanNumber)) {
      return StripeCardType.mastercard;
    }
    
    // American Express
    if (RegExp(r'^3[47]').hasMatch(cleanNumber)) {
      return StripeCardType.americanExpress;
    }
    
    // Discover
    if (RegExp(r'^6(?:011|5)').hasMatch(cleanNumber)) {
      return StripeCardType.discover;
    }
    
    // Diners Club
    if (RegExp(r'^3[0689]').hasMatch(cleanNumber)) {
      return StripeCardType.dinersClub;
    }
    
    // JCB
    if (RegExp(r'^35').hasMatch(cleanNumber)) {
      return StripeCardType.jcb;
    }
    
    // UnionPay
    if (RegExp(r'^62').hasMatch(cleanNumber)) {
      return StripeCardType.unionpay;
    }
    
    return StripeCardType.unknown;
  }

  /// Obtenir les informations spécifiques à un type de carte
  static StripeCardInfo getCardInfo(StripeCardType cardType) {
    switch (cardType) {
      case StripeCardType.visa:
        return StripeCardInfo(
          name: 'Visa',
          icon: Icons.credit_card,
          color: Colors.blue,
          maxLength: 19,
          cvcLength: 3,
          format: 'XXXX XXXX XXXX XXXX',
          testNumbers: ['4242 4242 4242 4242'],
        );
      case StripeCardType.mastercard:
        return StripeCardInfo(
          name: 'Mastercard',
          icon: Icons.credit_card,
          color: Colors.red,
          maxLength: 16,
          cvcLength: 3,
          format: 'XXXX XXXX XXXX XXXX',
          testNumbers: ['5555 5555 5555 4444', '2223 0031 2200 3222'],
        );
      case StripeCardType.americanExpress:
        return StripeCardInfo(
          name: 'American Express',
          icon: Icons.credit_card,
          color: Colors.green,
          maxLength: 15,
          cvcLength: 4,
          format: 'XXXX XXXXXX XXXXX',
          testNumbers: ['3782 822463 10005'],
        );
      case StripeCardType.discover:
        return StripeCardInfo(
          name: 'Discover',
          icon: Icons.credit_card,
          color: Colors.orange,
          maxLength: 16,
          cvcLength: 3,
          format: 'XXXX XXXX XXXX XXXX',
          testNumbers: ['6011 1111 1111 1117'],
        );
      case StripeCardType.dinersClub:
        return StripeCardInfo(
          name: 'Diners Club',
          icon: Icons.credit_card,
          color: Colors.purple,
          maxLength: 14,
          cvcLength: 3,
          format: 'XXXX XXXXXX XXXX',
          testNumbers: ['3056 930902 5904'],
        );
      case StripeCardType.jcb:
        return StripeCardInfo(
          name: 'JCB',
          icon: Icons.credit_card,
          color: Colors.indigo,
          maxLength: 16,
          cvcLength: 3,
          format: 'XXXX XXXX XXXX XXXX',
          testNumbers: ['3530 1113 3330 0000'],
        );
      case StripeCardType.unionpay:
        return StripeCardInfo(
          name: 'UnionPay',
          icon: Icons.credit_card,
          color: Colors.teal,
          maxLength: 19,
          cvcLength: 3,
          format: 'XXXX XXXX XXXX XXXX',
          testNumbers: ['6200 0000 0000 0005'],
        );
      case StripeCardType.unknown:
        return StripeCardInfo(
          name: 'Carte',
          icon: Icons.credit_card,
          color: Colors.grey,
          maxLength: 19,
          cvcLength: 4,
          format: 'XXXX XXXX XXXX XXXX',
          testNumbers: [],
        );
    }
  }
}

/// Informations spécifiques à un type de carte
class StripeCardInfo {
  final String name;
  final IconData icon;
  final Color color;
  final int maxLength;
  final int cvcLength;
  final String format;
  final List<String> testNumbers;

  StripeCardInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.maxLength,
    required this.cvcLength,
    required this.format,
    required this.testNumbers,
  });
}

/// Formulaire de paiement unifié et adaptatif
class UnifiedPaymentForm extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final Function(StripePaymentResult) onPaymentResult;
  final StripeCardType? preferredCardType;

  const UnifiedPaymentForm({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onPaymentResult,
    this.preferredCardType,
  });

  @override
  State<UnifiedPaymentForm> createState() => _UnifiedPaymentFormState();
}

class _UnifiedPaymentFormState extends State<UnifiedPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  bool _isProcessing = false;
  StripeCardType _detectedCardType = StripeCardType.unknown;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_onCardNumberChanged);
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final cardType = PaymentFormFactory.detectCardType(_cardNumberController.text);
    if (cardType != _detectedCardType) {
      setState(() {
        _detectedCardType = cardType;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final cardInfo = PaymentFormFactory.getCardInfo(_detectedCardType);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du paiement
            _buildPaymentHeader(cardInfo),
            const SizedBox(height: 24),

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
            const SizedBox(height: 16),

            // Numéro de carte avec détection automatique
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Numéro de carte',
                hintText: cardInfo.format,
                prefixIcon: Icon(cardInfo.icon, color: cardInfo.color),
                suffixIcon: _detectedCardType != StripeCardType.unknown
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: cardInfo.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cardInfo.name,
                          style: TextStyle(
                            color: cardInfo.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(cardInfo.maxLength),
                _CardNumberFormatter(cardInfo),
              ],
              validator: (value) => _validateCardNumber(value, cardInfo),
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
                    validator: _validateExpiryDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '0' * cardInfo.cvcLength,
                      prefixIcon: const Icon(Icons.security),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(cardInfo.cvcLength),
                    ],
                    validator: (value) => _validateCVV(value, cardInfo),
                  ),
                ),
              ],
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

            // Informations de sécurité et test
            _buildSecurityAndTestInfo(cardInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHeader(StripeCardInfo cardInfo) {
    return Container(
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
    );
  }

  Widget _buildSecurityAndTestInfo(StripeCardInfo cardInfo) {
    return Column(
      children: [
        // Message de sécurité
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
                    color: const Color(0xFF387D35),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Informations de test si disponibles
        if (cardInfo.testNumbers.isNotEmpty) ...[
          const SizedBox(height: 8),
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
                  '💳 Cartes de test ${cardInfo.name}:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                ...cardInfo.testNumbers.map((testNumber) => Text(
                  '• $testNumber',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                )),
                Text(
                  '• CVV: n\'importe quel code ${cardInfo.cvcLength} chiffres',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                ),
                Text(
                  '• Date: n\'importe quelle date future',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Traiter le paiement complet via le backend
      final result = await UnifiedPaymentService.processPayment(
        amount: widget.amount,
        currency: widget.currency,
        description: widget.description,
        metadata: {
          'source': 'vegnbio_app',
          'timestamp': DateTime.now().toIso8601String(),
        },
        cardNumber: _cardNumberController.text.replaceAll(RegExp(r'\s'), ''),
        expMonth: int.parse(_expiryDateController.text.split('/')[0]),
        expYear: int.parse(_expiryDateController.text.split('/')[1]),
        cvc: _cvvController.text,
        cardholderName: _cardholderNameController.text.trim(),
        context: context,
      );
      
      widget.onPaymentResult(result);
    } catch (e) {
      // print('❌ [UnifiedPaymentForm] Erreur lors du paiement: $e');
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

  String? _validateCardNumber(String? value, StripeCardInfo cardInfo) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir le numéro de carte';
    }
    
    final cleanNumber = value.replaceAll(RegExp(r'\s'), '');
    if (cleanNumber.length < 13 || cleanNumber.length > cardInfo.maxLength) {
      return 'Numéro de carte invalide';
    }
    
    // Validation de Luhn simplifiée
    if (!_isValidLuhn(cleanNumber)) {
      return 'Numéro de carte invalide';
    }
    
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date requise';
    }
    if (value.length != 5) {
      return 'Format MM/AA';
    }
    
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
  }

  String? _validateCVV(String? value, StripeCardInfo cardInfo) {
    if (value == null || value.isEmpty) {
      return 'CVV requis';
    }
    if (value.length != cardInfo.cvcLength) {
      return 'CVV invalide';
    }
    return null;
  }

  bool _isValidLuhn(String number) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
}

/// Formatter pour le numéro de carte adaptatif
class _CardNumberFormatter extends TextInputFormatter {
  final StripeCardInfo cardInfo;

  _CardNumberFormatter(this.cardInfo);

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

/// Formatter pour la date d'expiration
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length >= 2 && !text.contains('/')) {
      final month = text.substring(0, 2);
      final year = text.substring(2);
      return TextEditingValue(
        text: '$month/$year',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    return newValue;
  }
}
