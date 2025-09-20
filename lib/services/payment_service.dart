
class PaymentService {
  /// Simule un paiement Stripe
  /// En production, ceci serait remplacé par l'intégration Stripe réelle
  static Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Simulation d'un délai de traitement
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulation de succès (90% de chance)
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final isSuccess = random < 90;
      
      if (isSuccess) {
        return PaymentResult.success(
          paymentIntentId: 'pi_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          currency: currency,
        );
      } else {
        return PaymentResult.failure(
          errorCode: 'card_declined',
          errorMessage: 'Votre carte a été refusée. Veuillez essayer une autre carte.',
        );
      }
    } catch (e) {
      return PaymentResult.failure(
        errorCode: 'payment_failed',
        errorMessage: 'Erreur lors du traitement du paiement: $e',
      );
    }
  }

  /// Valide les informations de carte (simulation)
  static bool validateCardInfo({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  }) {
    // Simulation simple de validation
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s'), '');
    
    if (cleanCardNumber.length != 16) return false;
    if (expiryDate.length != 5 || !expiryDate.contains('/')) return false;
    if (cvv.length < 3 || cvv.length > 4) return false;
    if (cardholderName.trim().isEmpty) return false;
    
    return true;
  }

  /// Formate le numéro de carte pour l'affichage
  static String formatCardNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\s'), '');
    if (clean.length <= 4) return clean;
    
    final groups = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4).clamp(0, clean.length);
      groups.add(clean.substring(i, end));
    }
    
    return groups.join(' ');
  }

  /// Masque le numéro de carte pour l'affichage
  static String maskCardNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\s'), '');
    if (clean.length < 8) return clean;
    
    final start = clean.substring(0, 4);
    final end = clean.substring(clean.length - 4);
    final middle = '*' * (clean.length - 8);
    
    return '$start $middle $end';
  }
}

class PaymentResult {
  final bool isSuccess;
  final String? paymentIntentId;
  final double? amount;
  final String? currency;
  final String? errorCode;
  final String? errorMessage;

  PaymentResult._({
    required this.isSuccess,
    this.paymentIntentId,
    this.amount,
    this.currency,
    this.errorCode,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentIntentId,
    required double amount,
    required String currency,
  }) {
    return PaymentResult._(
      isSuccess: true,
      paymentIntentId: paymentIntentId,
      amount: amount,
      currency: currency,
    );
  }

  factory PaymentResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return PaymentResult._(
      isSuccess: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}
