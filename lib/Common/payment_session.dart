class PaymentSession {
  const PaymentSession({
    required this.paymentId,
    required this.orderId,
    required this.provider,
    required this.flow,
    required this.paymentStatus,
    required this.amount,
    required this.currency,
    this.checkoutUrl = '',
    this.clientSecret = '',
    this.publishableKey = '',
    this.customerId = '',
    this.ephemeralKey = '',
  });

  final String paymentId;
  final String orderId;
  final String provider;
  final String flow;
  final String paymentStatus;
  final double amount;
  final String currency;
  final String checkoutUrl;
  final String clientSecret;
  final String publishableKey;
  final String customerId;
  final String ephemeralKey;

  bool get isRedirect => flow == 'redirect';
  bool get isPaymentSheet => flow == 'payment_sheet';

  bool get canLaunch {
    if (isRedirect) return checkoutUrl.trim().isNotEmpty;
    if (isPaymentSheet) {
      return provider == 'stripe' &&
          clientSecret.trim().isNotEmpty &&
          publishableKey.trim().isNotEmpty;
    }
    return false;
  }

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    final checkoutUrl = _readText(json, const ['checkout_url', 'checkoutUrl']);
    final clientSecret = _readText(json, const [
      'client_secret',
      'clientSecret',
    ]);
    final publishableKey = _readText(json, const [
      'publishable_key',
      'publishableKey',
    ]);
    final rawFlow = _readText(json, const [
      'flow',
      'payment_flow',
      'paymentFlow',
    ]).toLowerCase();
    final flow = rawFlow.isNotEmpty
        ? rawFlow
        : checkoutUrl.isNotEmpty
        ? 'redirect'
        : clientSecret.isNotEmpty && publishableKey.isNotEmpty
        ? 'payment_sheet'
        : '';

    return PaymentSession(
      paymentId: _readText(json, const ['payment_id', 'paymentId']),
      orderId: _readText(json, const ['order_id', 'orderId']),
      provider: _readText(json, const [
        'provider',
      ], fallback: 'stripe').toLowerCase(),
      flow: flow,
      paymentStatus: _readText(json, const [
        'payment_status',
        'paymentStatus',
      ], fallback: 'pending'),
      amount: _readDouble(json, const ['amount']),
      currency: _readText(json, const [
        'currency',
      ], fallback: 'CAD').toUpperCase(),
      checkoutUrl: checkoutUrl,
      clientSecret: clientSecret,
      publishableKey: publishableKey,
      customerId: _readText(json, const ['customer_id', 'customerId']),
      ephemeralKey: _readText(json, const ['ephemeral_key', 'ephemeralKey']),
    );
  }
}

String _readText(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  final value = json[keys.firstWhere(json.containsKey, orElse: () => '')];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
