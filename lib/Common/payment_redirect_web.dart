// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> openExternalPaymentUrl(String url) async {
  final normalizedUrl = url.trim();
  if (normalizedUrl.isEmpty) return false;
  html.window.location.assign(normalizedUrl);
  return true;
}
