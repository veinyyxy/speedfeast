class BuyerFirebaseConfig {
  const BuyerFirebaseConfig._();

  static const webVapidKey = String.fromEnvironment(
    'BUYER_FIREBASE_WEB_VAPID_KEY',
  );

  static Future<String> loadWebVapidKey() async {
    return webVapidKey.trim();
  }
}
