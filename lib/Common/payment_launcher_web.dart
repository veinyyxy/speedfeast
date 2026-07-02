// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'payment_session.dart';

Future<bool> launchPaymentSession(PaymentSession session) async {
  final checkoutUrl = session.checkoutUrl.trim();
  if (checkoutUrl.isEmpty) return false;
  html.window.location.assign(checkoutUrl);
  return true;
}
