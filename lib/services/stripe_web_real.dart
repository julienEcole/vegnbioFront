// Implémentation Stripe.js réelle pour le web
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class StripeWebReal {
  static Future<void> initialize() async {
    if (!kIsWeb) {
      throw UnsupportedError('StripeWebReal ne peut être utilisé que sur le web');
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
      
      print('✅ [StripeWebReal] Stripe.js chargé avec succès');
    } catch (e) {
      print('❌ [StripeWebReal] Erreur lors du chargement de Stripe.js: $e');
      rethrow;
    }
  }

  static Future<String> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
    required String publishableKey,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('StripeWebReal ne peut être utilisé que sur le web');
    }
    
    try {
      // Vérifier que Stripe est disponible
      if (js.context['Stripe'] == null) {
        throw Exception('Stripe.js n\'est pas chargé');
      }
      
      // Créer l'instance Stripe
      final stripeConstructor = js.context['Stripe'];
      print('🔍 [StripeWebReal] Stripe constructor: $stripeConstructor');
      print('🔍 [StripeWebReal] Publishable key: $publishableKey');
      
      final stripe = stripeConstructor.apply([publishableKey]);
      print('🔍 [StripeWebReal] Stripe instance créée: $stripe');
      
      // Préparer les données de carte avec un format plus simple
      final paymentMethodParams = js.JsObject.jsify({
        'type': 'card',
        'card': {
          'number': cardNumber,
          'exp_month': expMonth,
          'exp_year': expYear,
          'cvc': cvc,
        },
        'billing_details': {
          'name': cardholderName,
        },
      });

      print('🔍 [StripeWebReal] Paramètres PaymentMethod: $paymentMethodParams');

      // Créer le PaymentMethod avec Stripe.js (asynchrone)
      print('🔄 [StripeWebReal] Création du PaymentMethod en cours...');
      
      // Utiliser une Promise JavaScript
      final promise = stripe.callMethod('createPaymentMethod', [paymentMethodParams]);
      
      // Attendre que la Promise se résolve
      final result = await _waitForPromise(promise);
      
      print('🔍 [StripeWebReal] Résultat Stripe: $result');
      
      // Vérifier si le résultat est null ou contient une erreur
      if (result == null) {
        throw Exception('Erreur Stripe: Aucune réponse reçue de l\'API');
      }
      
      // Log détaillé du contenu du résultat
      print('🔍 [StripeWebReal] Type du résultat: ${result.runtimeType}');
      print('🔍 [StripeWebReal] Clés du résultat: ${result.keys?.toList() ?? "Pas de clés"}');
      
      if (result['error'] != null) {
        final errorCode = result['error']['code'] ?? 'unknown';
        final errorMessage = result['error']['message'] ?? 'Erreur inconnue';
        final errorType = result['error']['type'] ?? 'unknown';
        print('❌ [StripeWebReal] Erreur détectée: [$errorType/$errorCode] $errorMessage');
        throw Exception('Erreur Stripe [$errorType/$errorCode]: $errorMessage');
      }

      if (result['paymentMethod'] == null) {
        print('❌ [StripeWebReal] Aucun PaymentMethod dans la réponse');
        print('🔍 [StripeWebReal] Contenu complet du résultat: $result');
        throw Exception('Erreur Stripe: Aucun PaymentMethod dans la réponse');
      }

      final paymentMethodId = result['paymentMethod']['id'] as String;
      if (paymentMethodId.isEmpty) {
        throw Exception('Erreur Stripe: ID du PaymentMethod vide');
      }
      
      print('✅ [StripeWebReal] PaymentMethod créé: $paymentMethodId');
      
      return paymentMethodId;
    } catch (e) {
      print('❌ [StripeWebReal] Erreur lors de la création du PaymentMethod: $e');
      rethrow;
    }
  }

  /// Attendre qu'une Promise JavaScript se résolve
  static Future<dynamic> _waitForPromise(js.JsObject promise) async {
    // Convertir la Promise JavaScript en Future Dart
    return await promise.callMethod('then', [
      (result) {
        print('✅ [StripeWebReal] Promise résolue: $result');
        
        // Vérifier si le résultat contient une erreur Stripe
        if (result != null && result['error'] != null) {
          final errorCode = result['error']['code'] ?? 'unknown';
          final errorMessage = result['error']['message'] ?? 'Erreur inconnue';
          final errorType = result['error']['type'] ?? 'unknown';
          print('❌ [StripeWebReal] Erreur détectée dans la réponse: [$errorType/$errorCode] $errorMessage');
          throw Exception('Erreur Stripe [$errorType/$errorCode]: $errorMessage');
        }
        
        return result;
      }
    ]).callMethod('catch', [
      (error) {
        print('❌ [StripeWebReal] Promise rejetée avec erreur: $error');
        throw Exception('Erreur Promise: $error');
      }
    ]);
  }
}
