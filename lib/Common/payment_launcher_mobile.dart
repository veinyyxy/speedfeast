import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'payment_session.dart';

Future<bool> launchPaymentSession(PaymentSession session) async {
  if (!session.isPaymentSheet || !session.canLaunch) return false;
  if (session.provider != 'stripe') return false;

  Stripe.publishableKey = session.publishableKey;
  await Stripe.instance.applySettings();

  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      merchantDisplayName: 'SpeedFeast',
      paymentIntentClientSecret: session.clientSecret,
      customerId: session.customerId.isEmpty ? null : session.customerId,
      customerEphemeralKeySecret: session.ephemeralKey.isEmpty
          ? null
          : session.ephemeralKey,
    ),
  );

  try {
    await Stripe.instance.presentPaymentSheet();
    return true;
  } on StripeException catch (e) {
    debugPrint('Stripe payment sheet failed or was cancelled: $e');
    return false;
  }
}
