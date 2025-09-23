// Implémentation Stripe Elements pour le web (sécurisée)
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class StripeWebElements {
  static js.JsObject? _stripe;
  static js.JsObject? _elements;
  static js.JsObject? _cardElement;

  static Future<void> initialize(String publishableKey) async {
    if (!kIsWeb) {
      throw UnsupportedError('StripeWebElements ne peut être utilisé que sur le web');
    }
    
    try {
      // Charger Stripe.js si pas déjà chargé
      final existingScript = html.document.querySelector('script[src*="js.stripe.com"]');
      if (existingScript == null) {
        final script = html.ScriptElement()
          ..src = 'https://js.stripe.com/v3/'
          ..type = 'text/javascript';
        
        html.document.head!.append(script);
        
        // Attendre que le script soit chargé
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      // Vérifier que Stripe est disponible
      if (js.context['Stripe'] == null) {
        throw Exception('Stripe.js n\'est pas chargé');
      }
      
      // Créer l'instance Stripe
      final stripeConstructor = js.context['Stripe'];
      _stripe = stripeConstructor.apply([publishableKey]);
      
      print('✅ [StripeWebElements] Stripe initialisé avec succès');
    } catch (e) {
      print('❌ [StripeWebElements] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Créer un élément de carte Stripe
  static Future<void> createCardElement() async {
    if (_stripe == null) {
      throw Exception('Stripe n\'est pas initialisé');
    }

    try {
      // Créer les Elements
      _elements = _stripe!.callMethod('elements');
      
      // Créer l'élément de carte
      _cardElement = _elements!.callMethod('create', ['card', {
        'style': {
          'base': {
            'fontSize': '16px',
            'color': '#424770',
            '::placeholder': {
              'color': '#aab7c4',
            },
          },
        },
      }]);
      
      print('✅ [StripeWebElements] CardElement créé');
    } catch (e) {
      print('❌ [StripeWebElements] Erreur lors de la création du CardElement: $e');
      rethrow;
    }
  }

  /// Monter l'élément de carte dans un conteneur
  static Future<void> mountCardElement(String containerId) async {
    if (_cardElement == null) {
      throw Exception('CardElement n\'est pas créé');
    }

    try {
      final container = html.document.getElementById(containerId);
      if (container == null) {
        throw Exception('Conteneur avec l\'ID $containerId non trouvé');
      }

      _cardElement!.callMethod('mount', ['#$containerId']);
      print('✅ [StripeWebElements] CardElement monté dans $containerId');
    } catch (e) {
      print('❌ [StripeWebElements] Erreur lors du montage: $e');
      rethrow;
    }
  }

  /// Créer un PaymentMethod avec Stripe Elements
  static Future<String> createPaymentMethod({
    required String cardholderName,
  }) async {
    if (_stripe == null || _cardElement == null) {
      throw Exception('Stripe ou CardElement n\'est pas initialisé');
    }

    try {
      print('🔄 [StripeWebElements] Création du PaymentMethod...');
      
      // Créer le PaymentMethod avec l'élément de carte
      final paymentMethodParams = js.JsObject.jsify({
        'type': 'card',
        'card': _cardElement,
        'billing_details': {
          'name': cardholderName,
        },
      });

      // Utiliser une Promise JavaScript
      final promise = _stripe!.callMethod('createPaymentMethod', [paymentMethodParams]);
      
      // Attendre que la Promise se résolve
      final result = await _waitForPromise(promise);
      
      if (result['error'] != null) {
        final errorCode = result['error']['code'] ?? 'unknown';
        final errorMessage = result['error']['message'] ?? 'Erreur inconnue';
        final errorType = result['error']['type'] ?? 'unknown';
        throw Exception('Erreur Stripe [$errorType/$errorCode]: $errorMessage');
      }

      if (result['paymentMethod'] == null) {
        throw Exception('Erreur Stripe: Aucun PaymentMethod dans la réponse');
      }

      final paymentMethodId = result['paymentMethod']['id'] as String;
      print('✅ [StripeWebElements] PaymentMethod créé: $paymentMethodId');
      
      return paymentMethodId;
    } catch (e) {
      print('❌ [StripeWebElements] Erreur lors de la création du PaymentMethod: $e');
      rethrow;
    }
  }

  /// Attendre qu'une Promise JavaScript se résolve
  static Future<dynamic> _waitForPromise(js.JsObject promise) async {
    return await promise.callMethod('then', [
      (result) {
        print('✅ [StripeWebElements] Promise résolue: $result');
        return result;
      }
    ]).callMethod('catch', [
      (error) {
        print('❌ [StripeWebElements] Promise rejetée: $error');
        throw Exception('Erreur Promise: $error');
      }
    ]);
  }

  /// Démontrer l'élément de carte
  static void unmountCardElement() {
    if (_cardElement != null) {
      try {
        _cardElement!.callMethod('unmount');
        print('✅ [StripeWebElements] CardElement démonté');
      } catch (e) {
        print('❌ [StripeWebElements] Erreur lors du démontage: $e');
      }
    }
  }
}
