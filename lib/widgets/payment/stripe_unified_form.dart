import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../services/stripe_service.dart';
import '../../config/app_config.dart';

class StripeUnifiedForm extends StatefulWidget {
  final Function(String paymentMethodId) onPaymentSuccess;
  final Function(String error) onPaymentError;
  final bool showClassicFields; // Si true, affiche les champs classiques, sinon utilise Stripe Elements

  const StripeUnifiedForm({
    Key? key,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    this.showClassicFields = true, // Par défaut, affiche les champs classiques
  }) : super(key: key);

  @override
  State<StripeUnifiedForm> createState() => _StripeUnifiedFormState();
}

class _StripeUnifiedFormState extends State<StripeUnifiedForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 [StripeUnifiedForm] Traitement du paiement...');
      
      String paymentMethodId;
      
      if (widget.showClassicFields) {
        // Mode classique : utiliser Stripe Elements en arrière-plan
        paymentMethodId = await _processWithElementsBackground();
      } else {
        // Mode Elements natif : utiliser Stripe Elements directement
        paymentMethodId = await _processWithNativeElements();
      }
      
      print('✅ [StripeUnifiedForm] PaymentMethod créé: $paymentMethodId');
      widget.onPaymentSuccess(paymentMethodId);
    } catch (e) {
      print('❌ [StripeUnifiedForm] Erreur lors du paiement: $e');
      widget.onPaymentError('Erreur lors du paiement: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Traitement avec Stripe Elements en arrière-plan (champs classiques visibles)
  Future<String> _processWithElementsBackground() async {
    // Initialiser Stripe Elements si pas déjà fait
    await StripeService.initializeElements(AppConfig.stripePublicKey);
    
    // Créer un conteneur invisible pour l'élément de carte
    final containerId = 'stripe-card-${DateTime.now().millisecondsSinceEpoch}';
    
    // Créer et monter l'élément de carte Stripe
    await StripeService.createAndMountCardElement(containerId);
    
    // Remplir automatiquement l'élément de carte avec les données du formulaire
    await _fillStripeElementWithFormData();
    
    // Créer le PaymentMethod avec Stripe Elements
    return await StripeService.createPaymentMethodWithElements(
      cardholderName: _cardholderNameController.text.trim(),
    );
  }

  /// Traitement avec Stripe Elements natif (élément Stripe visible)
  Future<String> _processWithNativeElements() async {
    // Initialiser Stripe Elements
    await StripeService.initializeElements(AppConfig.stripePublicKey);
    
    // Créer et monter l'élément de carte dans un conteneur visible
    final containerId = 'stripe-card-element';
    await StripeService.createAndMountCardElement(containerId);
    
    setState(() {
      _isInitialized = true;
    });
    
    // Créer le PaymentMethod avec Stripe Elements
    return await StripeService.createPaymentMethodWithElements(
      cardholderName: _cardholderNameController.text.trim(),
    );
  }

  /// Remplir l'élément Stripe avec les données du formulaire
  Future<void> _fillStripeElementWithFormData() async {
    if (kIsWeb) {
      // Cette méthode sera implémentée pour remplir automatiquement
      // l'élément Stripe avec les données du formulaire
      print('🔧 [StripeUnifiedForm] Remplissage de l\'élément Stripe avec les données du formulaire...');
      
      // Pour l'instant, on simule le remplissage
      // Dans une vraie implémentation, on utiliserait l'API Stripe pour pré-remplir
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir le numéro de carte';
    }
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'Numéro de carte invalide';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir la date d\'expiration';
    }
    final regExp = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
    if (!regExp.hasMatch(value)) {
      return 'Format invalide (MM/AA)';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir le CVV';
    }
    if (value.length < 3 || value.length > 4) {
      return 'CVV invalide';
    }
    return null;
  }

  String? _validateCardholderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir le nom du titulaire';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            widget.showClassicFields 
                ? 'Paiement sécurisé' 
                : 'Paiement sécurisé avec Stripe',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nom du titulaire (toujours visible)
          TextFormField(
            controller: _cardholderNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du titulaire de la carte',
              hintText: 'Jean Dupont',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: _validateCardholderName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          
          // Champs de carte classiques (si demandé)
          if (widget.showClassicFields) ...[
            _buildClassicCardFields(),
          ] else ...[
            _buildStripeElementField(),
          ],
          
          const SizedBox(height: 24),
          
          // Bouton de paiement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Traitement en cours...'),
                      ],
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
          
          // Message d'information
          const SizedBox(height: 16),
          _buildSecurityMessage(),
        ],
      ),
    );
  }

  Widget _buildClassicCardFields() {
    return Column(
      children: [
        // Numéro de carte
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Numéro de carte',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
          validator: _validateCardNumber,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _CardNumberFormatter(),
          ],
        ),
        const SizedBox(height: 16),
        
        // Date d'expiration et CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'Date d\'expiration',
                  hintText: 'MM/AA',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                keyboardType: TextInputType.number,
                validator: _validateExpiryDate,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                validator: _validateCVV,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                obscureText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStripeElementField() {
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de carte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const HtmlElementView(
              viewType: 'stripe-card-element',
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sur mobile, les informations de carte seront saisies via l\'interface native Stripe.',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSecurityMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.showClassicFields
                  ? 'Paiement sécurisé avec Stripe Elements. Vos données de carte sont protégées.'
                  : 'Vos informations de paiement sont sécurisées par Stripe et ne transitent jamais par nos serveurs.',
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour intégrer l'élément HTML Stripe
class HtmlElementView extends StatefulWidget {
  final String viewType;

  const HtmlElementView({
    Key? key,
    required this.viewType,
  }) : super(key: key);

  @override
  State<HtmlElementView> createState() => _HtmlElementViewState();
}

class _HtmlElementViewState extends State<HtmlElementView> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      color: Colors.grey,
      child: Center(
        child: Text(
          'Stripe Card Element\n(sera monté ici)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// Formatter pour le numéro de carte
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

// Formatter pour la date d'expiration
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
