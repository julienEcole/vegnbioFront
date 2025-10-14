// Implémentation Stripe Elements pour le web (sécurisée)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
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
      final existingScript = web.document.querySelector('script[src*="js.stripe.com"]');
      if (existingScript == null) {
        // print('🔄 [StripeWebElements] Chargement de Stripe.js...');
        
        final script = web.document.createElement('script');
        script.setAttribute('src', 'https://js.stripe.com/v3/');
        script.setAttribute('type', 'text/javascript');
        
        // Attendre que le script soit chargé avec une Promise
        final scriptLoaded = _waitForScriptLoad(script);
        web.document.head!.append(script);
        
        // Attendre que le script soit complètement chargé
        await scriptLoaded;
        // print('✅ [StripeWebElements] Script Stripe.js chargé');
      } else {
        // print('✅ [StripeWebElements] Script Stripe.js déjà présent');
      }
      
      // Attendre un peu plus pour s'assurer que Stripe est disponible
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier que Stripe est disponible
      if (js.context['Stripe'] == null) {
        // print('❌ [StripeWebElements] Stripe non disponible dans js.context');
        throw Exception('Stripe.js n\'est pas chargé');
      }
      
      // Créer l'instance Stripe
      final stripeConstructor = js.context['Stripe'];
      _stripe = stripeConstructor.apply([publishableKey]);
      
      // print('✅ [StripeWebElements] Stripe initialisé avec succès');
    } catch (e) {
      // print('❌ [StripeWebElements] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Attendre qu'un script soit chargé
  static Future<void> _waitForScriptLoad(web.Element script) async {
    final completer = Completer<void>();
    
    // Créer un callback JavaScript pour détecter le chargement
    final onLoadCallback = js.allowInterop((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    
    final onErrorCallback = js.allowInterop((_) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Erreur lors du chargement du script Stripe'));
      }
    });
    
    // Attacher les événements
    script.addEventListener('load', onLoadCallback as web.EventListener);
    script.addEventListener('error', onErrorCallback as web.EventListener);
    
    // Timeout de sécurité
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Timeout lors du chargement du script Stripe'));
      }
    });
    
    return completer.future;
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
      
      // print('✅ [StripeWebElements] CardElement créé');
    } catch (e) {
      // print('❌ [StripeWebElements] Erreur lors de la création du CardElement: $e');
      rethrow;
    }
  }

  /// Monter l'élément de carte dans un conteneur
  static Future<void> mountCardElement(String containerId) async {
    if (_cardElement == null) {
      throw Exception('CardElement n\'est pas créé');
    }

    try {
      final container = web.document.getElementById(containerId);
      if (container == null) {
        throw Exception('Conteneur avec l\'ID $containerId non trouvé');
      }

      _cardElement!.callMethod('mount', ['#$containerId']);
      // print('✅ [StripeWebElements] CardElement monté dans $containerId');
    } catch (e) {
      // print('❌ [StripeWebElements] Erreur lors du montage: $e');
      rethrow;
    }
  }

  /// Créer un PaymentMethod avec Stripe Elements (approche avec montage)
  static Future<String> createPaymentMethodWithElements({
    required String cardholderName,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
  }) async {
    if (_stripe == null) {
      throw Exception('Stripe n\'est pas initialisé');
    }

    // Créer un conteneur temporaire
    final containerId = 'stripe-temp-${DateTime.now().millisecondsSinceEpoch}';
    final container = web.document.createElement('div');
    container.setAttribute('id', containerId);
    container.setAttribute('style', 'position: fixed; top: -9999px; left: -9999px; width: 1px; height: 1px; opacity: 0; pointer-events: none;');
    web.document.body!.append(container);

    try {
      // print('🔄 [StripeWebElements] Création du PaymentMethod avec Elements...');
      
      // Créer les Elements si pas déjà fait
      if (_elements == null) {
        _elements = _stripe!.callMethod('elements');
      }
      
      // Créer un élément de carte
      final cardElement = _elements!.callMethod('create', ['card', js.JsObject.jsify({
        'style': {
          'base': {
            'fontSize': '16px',
            'color': '#424770',
          },
        },
      })]);
      
      // Monter l'élément dans le conteneur temporaire
      cardElement.callMethod('mount', ['#$containerId']);
      
      // Attendre que l'élément soit monté
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Créer le PaymentMethod avec l'élément monté
      final paymentMethodParams = js.JsObject.jsify({
        'type': 'card',
        'card': cardElement,
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
      // print('✅ [StripeWebElements] PaymentMethod créé: $paymentMethodId');
      
      return paymentMethodId;
    } catch (e) {
      // print('❌ [StripeWebElements] Erreur lors de la création du PaymentMethod: $e');
      
      // Si c'est un problème d'AdBlocker, propager l'erreur avec un message spécifique
      if (e.toString().contains('ERR_BLOCKED_BY_CLIENT') || 
          e.toString().contains('Failed to fetch') ||
          e.toString().contains('ERR_BLOCKED_BY_ADBLOCKER') ||
          e.toString().contains('net::ERR_BLOCKED_BY_CLIENT')) {
        throw Exception('ERR_BLOCKED_BY_CLIENT: Stripe bloqué par AdBlocker');
      }
      
      rethrow;
    } finally {
      // Nettoyer le conteneur temporaire
      container.remove();
    }
  }


  /// Attendre qu'une Promise JavaScript se résolve
  static Future<dynamic> _waitForPromise(js.JsObject promise) async {
    return await promise.callMethod('then', [
      (result) {
        // print('✅ [StripeWebElements] Promise résolue: $result');
        return result;
      }
    ]).callMethod('catch', [
      (error) {
        // print('❌ [StripeWebElements] Promise rejetée: $error');
        throw Exception('Erreur Promise: $error');
      }
    ]);
  }

  /// Démontrer l'élément de carte
  static void unmountCardElement() {
    if (_cardElement != null) {
      try {
        _cardElement!.callMethod('unmount');
        // print('✅ [StripeWebElements] CardElement démonté');
      } catch (e) {
        // print('❌ [StripeWebElements] Erreur lors du démontage: $e');
      }
    }
  }
}
