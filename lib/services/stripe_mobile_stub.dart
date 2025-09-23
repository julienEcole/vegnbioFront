// Stub pour éviter les erreurs de compilation sur mobile
class StripeWebReal {
  static Future<void> initialize() async {
    throw UnsupportedError('StripeWebReal ne peut être utilisé que sur le web');
  }

  static Future<String> createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
    required String publishableKey,
  }) async {
    throw UnsupportedError('StripeWebReal ne peut être utilisé que sur le web');
  }
}
