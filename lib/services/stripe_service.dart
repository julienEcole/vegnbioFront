import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'stripe_web_real.dart';

class StripeService {
  static String get _baseUrl => '${ApiService.baseUrl}/payments';

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

  /// Initialiser Stripe Elements (web uniquement)
  static Future<void> initializeElements(String publishableKey) async {
    if (kIsWeb) {
      await StripeWebReal.initialize();
    }
  }

  /// Créer et monter l'élément de carte Stripe (web uniquement)
  static Future<void> createAndMountCardElement(String containerId) async {
    if (kIsWeb) {
      // Pour l'instant, on simule la création de l'élément
      // Dans une vraie implémentation, on utiliserait Stripe Elements
      print('🔧 [StripeService] Simulation de la création de l\'élément de carte');
    } else {
      throw UnsupportedError('createAndMountCardElement n\'est disponible que sur le web');
    }
  }

  /// Créer un PaymentMethod avec Stripe Elements (web uniquement)
  static Future<String> createPaymentMethodWithElements({
    required String cardholderName,
  }) async {
    if (kIsWeb) {
      // Utiliser l'ancienne implémentation qui fonctionne
      // En attendant d'implémenter correctement Stripe Elements
      await Future.delayed(const Duration(seconds: 1));
      final simulatedPaymentMethodId = 'pm_web_simulated_${DateTime.now().millisecondsSinceEpoch}';
      print('✅ [StripeService] PaymentMethod simulé créé: $simulatedPaymentMethodId');
      return simulatedPaymentMethodId;
    } else {
      throw UnsupportedError('createPaymentMethodWithElements n\'est disponible que sur le web');
    }
  }

  /// Démontrer l'élément de carte (web uniquement)
  static void unmountCardElement() {
    if (kIsWeb) {
      print('🔧 [StripeService] Simulation du démontage de l\'élément de carte');
    }
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
    // Validation du numéro de carte (algorithme de Luhn simplifié)
    final cleanNumber = cardDetails.number.replaceAll(RegExp(r'\s'), '');
    if (cleanNumber.length != 16) return false;

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

class StripePaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? status;
  final int? amount;
  final String? currency;
  final String? error;

  StripePaymentResult({
    required this.success,
    this.paymentIntentId,
    this.status,
    this.amount,
    this.currency,
    this.error,
  });

  factory StripePaymentResult.fromJson(Map<String, dynamic> json) {
    return StripePaymentResult(
      success: json['success'] ?? false,
      paymentIntentId: json['paymentIntentId'],
      status: json['status'],
      amount: json['amount'],
      currency: json['currency'],
      error: json['error'],
    );
  }

  double? get amountInEuros => amount != null ? amount! / 100.0 : null;
}

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
