import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../config/app_config.dart';
import '../services/stripe_web_real.dart' if (dart.library.io) '../services/stripe_mobile_stub.dart';

/// Factory pour créer les instances Stripe selon la plateforme
class StripeFactory {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }
  }

  static Future<String> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    if (kIsWeb) {
      return await _createPaymentMethodWeb(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
      );
    } else {
      return await _createPaymentMethodMobile(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
      );
    }
  }

  // ==================== WEB IMPLEMENTATION ====================
  
  static Future<void> _initializeWeb() async {
    try {
      await StripeWebReal.initialize();
      print('✅ [StripeFactory] Stripe initialisé pour le web avec Stripe.js');
    } catch (e) {
      print('❌ [StripeFactory] Erreur lors de l\'initialisation web: $e');
      rethrow;
    }
  }

  static Future<String> _createPaymentMethodWeb({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      return await StripeWebReal.createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
        publishableKey: AppConfig.stripePublicKey,
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du PaymentMethod (Web): $e');
    }
  }

  // ==================== MOBILE IMPLEMENTATION ====================
  
  static Future<void> _initializeMobile() async {
    try {
      // Initialiser flutter_stripe pour mobile
      Stripe.publishableKey = AppConfig.stripePublicKey;
      await Stripe.instance.applySettings();
      print('✅ [StripeFactory] flutter_stripe initialisé pour mobile');
    } catch (e) {
      print('❌ [StripeFactory] Erreur lors de l\'initialisation mobile: $e');
    }
  }

  static Future<String> _createPaymentMethodMobile({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      // Créer le PaymentMethod avec flutter_stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: cardholderName,
            ),
          ),
        ),
      );
      
      print('✅ [StripeFactory] PaymentMethod mobile créé: ${paymentMethod.id}');
      return paymentMethod.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du PaymentMethod (Mobile): $e');
    }
  }
}
