import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart' as flutter_stripe;
import '../api_service.dart';
import '../../config/app_config.dart';
import '../../widgets/payment/adblocker_dialog.dart';

/// Service de paiement unifié utilisant Stripe
class UnifiedPaymentService {
  static String get _baseUrl => '${ApiService.baseUrl}/payments';

  /// Initialiser le service de paiement
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await _initializeStripeWeb();
      } else {
        await _initializeMobile();
      }
      print('✅ [UnifiedPaymentService] Stripe initialisé avec succès');
    } catch (e) {
      print('❌ [UnifiedPaymentService] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Initialisation pour le web
  static Future<void> _initializeStripeWeb() async {
    try {
      // Attendre que Stripe.js soit chargé
      int attempts = 0;
      while (js.context['Stripe'] == null && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (js.context['Stripe'] == null) {
        throw Exception('Stripe.js n\'est pas chargé après 5 secondes');
      }
      
      print('🌐 [UnifiedPaymentService] Stripe.js détecté pour le web');
    } catch (e) {
      print('❌ [UnifiedPaymentService] Erreur lors de l\'initialisation web: $e');
      rethrow;
    }
  }

  /// Initialisation pour mobile
  static Future<void> _initializeMobile() async {
    try {
      flutter_stripe.Stripe.publishableKey = AppConfig.stripePublicKey;
      await flutter_stripe.Stripe.instance.applySettings();
      print('📱 [UnifiedPaymentService] flutter_stripe initialisé pour mobile');
    } catch (e) {
      print('❌ [UnifiedPaymentService] Erreur lors de l\'initialisation mobile: $e');
      rethrow;
    }
  }

  /// Créer un PaymentIntent côté backend
  static Future<StripePaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
    String? description,
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'description': description,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripePaymentIntent.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de la création du PaymentIntent');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Créer un PaymentMethod selon la plateforme (déprécié - utiliser processPayment)
  @Deprecated('Utiliser processPayment() à la place')
  static Future<String> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
    BuildContext? context,
  }) async {
    // Cette méthode est dépréciée, utiliser processPayment à la place
    throw UnsupportedError('Utiliser processPayment() à la place de createPaymentMethod()');
  }

  /// Traiter un paiement complet via le backend avec tokenisation
  static Future<StripePaymentResult> processPayment({
    required double amount,
    required String currency,
    String? description,
    Map<String, String>? metadata,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
    BuildContext? context,
  }) async {
    try {
      print('🔄 [UnifiedPaymentService] Traitement du paiement avec tokenisation...');
      
      // Créer un token Stripe côté frontend
      final stripeToken = await _createStripeToken(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
      );
      
      print('✅ [UnifiedPaymentService] Token créé: ${stripeToken.substring(0, 10)}...');
      
      // Appeler l'API backend avec le token
      final response = await http.post(
        Uri.parse('$_baseUrl/process-payment'),
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'description': description,
          'metadata': metadata ?? {},
          'stripeToken': stripeToken,
          'cardholderName': cardholderName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [UnifiedPaymentService] Paiement traité avec succès');
        return StripePaymentResult.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors du traitement du paiement');
      }
    } catch (e) {
      print('❌ [UnifiedPaymentService] Erreur lors du traitement du paiement: $e');
      
      // Si c'est un problème d'AdBlocker, afficher le dialog informatif
      if (e.toString().contains('ERR_BLOCKED_BY_CLIENT') || 
          e.toString().contains('Failed to fetch') ||
          e.toString().contains('ERR_BLOCKED_BY_ADBLOCKER') ||
          e.toString().contains('net::ERR_BLOCKED_BY_CLIENT')) {
        
        if (context != null) {
          await AdBlockerDialog.show(context);
        }
        
        throw Exception('Stripe bloqué par AdBlocker. Veuillez désactiver votre AdBlocker pour localhost:8080 ou ajouter *.stripe.com aux sites autorisés.');
      }
      
      rethrow;
    }
  }

  /// Créer un token Stripe côté frontend
  static Future<String> _createStripeToken({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      print('🔄 [UnifiedPaymentService] Création du token Stripe...');
      
      if (kIsWeb) {
        return await _createStripeTokenWeb(
          cardNumber: cardNumber,
          expMonth: expMonth,
          expYear: expYear,
          cvc: cvc,
          cardholderName: cardholderName,
        );
      } else {
        return await _createStripeTokenMobile(
          cardNumber: cardNumber,
          expMonth: expMonth,
          expYear: expYear,
          cvc: cvc,
          cardholderName: cardholderName,
        );
      }
    } catch (e) {
      print('❌ [UnifiedPaymentService] Erreur lors de la création du token: $e');
      rethrow;
    }
  }

  /// Créer un token Stripe pour web
  static Future<String> _createStripeTokenWeb({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      print('🔄 [UnifiedPaymentService] Création du PaymentMethod via API backend...');
      
      // Appeler l'API backend pour créer un vrai PaymentMethod Stripe
      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment-method'),
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode({
          'cardNumber': cardNumber,
          'expMonth': expMonth,
          'expYear': expYear,
          'cvc': cvc,
          'cardholderName': cardholderName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentMethodId = data['paymentMethodId'] as String;
        
        print('✅ [UnifiedPaymentService] PaymentMethod créé: $paymentMethodId');
        print('💳 [UnifiedPaymentService] Carte: ${data['card']['brand']} **** ${data['card']['last4']}');
        
        return paymentMethodId;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de la création du PaymentMethod');
      }
      
    } catch (e) {
      print('❌ [UnifiedPaymentService] Erreur création PaymentMethod: $e');
      rethrow;
    }
  }

  /// Créer un token Stripe pour mobile
  static Future<String> _createStripeTokenMobile({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    // Utiliser flutter_stripe pour créer un token
    final token = await flutter_stripe.Stripe.instance.createToken(
      flutter_stripe.CreateTokenParams.card(
        params: flutter_stripe.CardTokenParams(
          name: cardholderName,
        ),
      ),
    );
    
    return token.id;
  }

  /// Confirmer un PaymentIntent avec un PaymentMethod
  static Future<StripePaymentResult> confirmPaymentIntent({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/confirm-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripePaymentResult.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de la confirmation du paiement');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer un PaymentIntent
  static Future<StripePaymentIntent> getPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment-intent/$paymentIntentId'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StripePaymentIntent.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de la récupération du PaymentIntent');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Annuler un PaymentIntent
  static Future<bool> cancelPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cancel-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          ...ApiService.headers,
        },
        body: json.encode({
          'paymentIntentId': paymentIntentId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Valider les détails d'une carte
  static bool validateCardDetails(StripeCardDetails cardDetails) {
    // Validation du numéro de carte (algorithme de Luhn)
    final cleanNumber = cardDetails.number.replaceAll(RegExp(r'\s'), '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) return false;
    if (!_isValidLuhn(cleanNumber)) return false;

    // Validation de la date d'expiration
    final now = DateTime.now();
    final expYear = 2000 + cardDetails.expYear;
    final expDate = DateTime(expYear, cardDetails.expMonth);
    if (expDate.isBefore(now)) return false;

    // Validation du CVV
    if (cardDetails.cvc.length < 3 || cardDetails.cvc.length > 4) return false;

    // Validation du nom
    if (cardDetails.name.trim().isEmpty) return false;

    return true;
  }

  /// Algorithme de Luhn pour valider les numéros de carte
  static bool _isValidLuhn(String number) {
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

  /// Formater le numéro de carte
  static String formatCardNumber(String number) {
    final clean = number.replaceAll(RegExp(r'\s'), '');
    if (clean.length <= 4) return clean;
    
    final groups = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4).clamp(0, clean.length);
      groups.add(clean.substring(i, end));
    }
    
    return groups.join(' ');
  }

  /// Masquer le numéro de carte
  static String maskCardNumber(String number) {
    final clean = number.replaceAll(RegExp(r'\s'), '');
    if (clean.length < 8) return clean;
    
    final start = clean.substring(0, 4);
    final end = clean.substring(clean.length - 4);
    final middle = '*' * (clean.length - 8);
    
    return '$start $middle $end';
  }
}

/// Modèle PaymentIntent Stripe
class StripePaymentIntent {
  final String clientSecret;
  final String paymentIntentId;
  final int amount;
  final String currency;
  final String status;

  StripePaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory StripePaymentIntent.fromJson(Map<String, dynamic> json) {
    return StripePaymentIntent(
      clientSecret: json['clientSecret'],
      paymentIntentId: json['paymentIntentId'],
      amount: json['amount'],
      currency: json['currency'],
      status: json['status'],
    );
  }

  double get amountInEuros => amount / 100.0;
}

/// Modèle détails de carte
class StripeCardDetails {
  final String number;
  final int expMonth;
  final int expYear;
  final String cvc;
  final String name;

  StripeCardDetails({
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.cvc,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'exp_month': expMonth,
      'exp_year': expYear,
      'cvc': cvc,
      'name': name,
    };
  }
}

/// Modèle résultat de paiement
class StripePaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? paymentMethodId;
  final String? status;
  final int? amount;
  final String? currency;
  final String? cardBrand;
  final String? cardLast4;
  final String? error;

  StripePaymentResult({
    required this.success,
    this.paymentIntentId,
    this.paymentMethodId,
    this.status,
    this.amount,
    this.currency,
    this.cardBrand,
    this.cardLast4,
    this.error,
  });

  factory StripePaymentResult.fromJson(Map<String, dynamic> json) {
    return StripePaymentResult(
      success: json['success'] ?? false,
      paymentIntentId: json['paymentIntentId'],
      paymentMethodId: json['paymentMethodId'],
      status: json['status'],
      amount: json['amount'],
      currency: json['currency'],
      cardBrand: json['card']?['brand'],
      cardLast4: json['card']?['last4'],
      error: json['error'],
    );
  }

  double? get amountInEuros => amount != null ? amount! / 100.0 : null;
}

/// Modèle PaymentMethod
class StripePaymentMethod {
  final String paymentMethodId;
  final String type;
  final Map<String, dynamic>? card;

  StripePaymentMethod({
    required this.paymentMethodId,
    required this.type,
    this.card,
  });

  factory StripePaymentMethod.fromJson(Map<String, dynamic> json) {
    return StripePaymentMethod(
      paymentMethodId: json['paymentMethodId'],
      type: json['type'],
      card: json['card'],
    );
  }
}
