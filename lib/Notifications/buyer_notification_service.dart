import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Common/buyer_firebase_config.dart';
import '../firebase_options.dart';
import 'buyer_notification_channels.dart';
import 'buyer_notification_models.dart';
import 'buyer_web_notification_click_stub.dart'
    if (dart.library.html) 'buyer_web_notification_click_web.dart';

typedef BuyerNotificationTokenHandler = Future<void> Function(String token);
typedef BuyerNotificationTapHandler =
    Future<void> Function(BuyerNotificationRouteIntent intent);

@pragma('vm:entry-point')
Future<void> buyerFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await _initializeBuyerFirebaseApp();
  } catch (error) {
    debugPrint('Firebase background initialization skipped: $error');
  }
}

Future<bool> _initializeBuyerFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) return true;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on UnsupportedError catch (error) {
    debugPrint('Buyer Firebase options are not configured: $error');
    return false;
  } catch (error) {
    debugPrint('Buyer Firebase initialization failed: $error');
    return false;
  }
}

class BuyerNotificationService {
  BuyerNotificationService._();

  static final BuyerNotificationService instance = BuyerNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  BuyerNotificationTokenHandler? _onToken;
  BuyerNotificationTapHandler? _onTap;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _localInitialized = false;
  bool _firebaseInitialized = false;

  bool get isFirebaseInitialized => _firebaseInitialized;

  Future<void> initialize({
    required BuyerNotificationTokenHandler onToken,
    required BuyerNotificationTapHandler onTap,
  }) async {
    _onToken = onToken;
    _onTap = onTap;

    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;
        _onTap?.call(BuyerNotificationRouteIntent.fromPayload(payload));
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      for (final channel in BuyerNotificationChannels.androidChannels) {
        await androidPlugin.createNotificationChannel(channel);
      }
      await androidPlugin.requestNotificationsPermission();
    }

    _localInitialized = true;
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_firebaseInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        final ready = await _initializeBuyerFirebaseApp();
        if (!ready) {
          debugPrint(
            'Buyer notifications are disabled: Firebase is not ready.',
          );
          return;
        }
      }

      final messaging = FirebaseMessaging.instance;
      final supported = await messaging.isSupported();
      if (!supported) {
        debugPrint(
          'Firebase messaging is not supported in this browser or origin.',
        );
        return;
      }
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _messageSubscription?.cancel();
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );

      _openedSubscription?.cancel();
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _onTap?.call(_intentFromRemoteMessage(message)),
      );
      attachBuyerWebNotificationClickListener(
        (data) => _onTap?.call(_intentFromData(data)),
      );

      _tokenSubscription?.cancel();
      _tokenSubscription = messaging.onTokenRefresh.listen((token) {
        _onToken?.call(token);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        scheduleMicrotask(
          () => _onTap?.call(_intentFromRemoteMessage(initialMessage)),
        );
      }

      _firebaseInitialized = true;
      await registerCurrentToken();
    } catch (error) {
      _firebaseInitialized = false;
      debugPrint('Firebase Messaging initialization skipped: $error');
    }
  }

  Future<void> registerCurrentToken() async {
    if (!_firebaseInitialized) return;
    try {
      final token = await _readCurrentToken();
      if (token == null || token.trim().isEmpty) return;
      await _onToken?.call(token);
    } catch (error) {
      debugPrint('Unable to read FCM token: $error');
    }
  }

  Future<String?> currentToken() async {
    if (!_firebaseInitialized) return null;
    try {
      return _readCurrentToken();
    } catch (error) {
      debugPrint('Unable to read current FCM token: $error');
      return null;
    }
  }

  Future<String?> _readCurrentToken() async {
    if (kIsWeb) {
      final webVapidKey = await BuyerFirebaseConfig.loadWebVapidKey();
      if (webVapidKey.isEmpty) {
        debugPrint('BUYER_FIREBASE_WEB_VAPID_KEY is not configured.');
        return null;
      }
      return FirebaseMessaging.instance.getToken(
        vapidKey: webVapidKey,
        serviceWorkerScriptPath: '/firebase-messaging-sw.js',
      );
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? _readDataText(message.data, 'title');
    final body = notification?.body ?? _readDataText(message.data, 'body');
    final eventType = _readDataText(message.data, 'event_type').isNotEmpty
        ? _readDataText(message.data, 'event_type')
        : _readDataText(message.data, 'type');
    final channelId = BuyerNotificationChannels.resolveChannelId(eventType);
    final intent = _intentFromRemoteMessage(message);

    await _localNotifications.show(
      id: _notificationId(message),
      title: title.isNotEmpty ? title : 'SpeedFeast',
      body: body.isNotEmpty ? body : 'You have a new notification.',
      notificationDetails: NotificationDetails(
        android: BuyerNotificationChannels.androidDetails(channelId),
        iOS: BuyerNotificationChannels.darwinDetails,
      ),
      payload: intent.toPayload(),
    );
  }

  BuyerNotificationRouteIntent _intentFromRemoteMessage(RemoteMessage message) {
    return _intentFromData(message.data);
  }

  BuyerNotificationRouteIntent _intentFromData(Map<String, dynamic> data) {
    final actionPayload = _readPayloadMap(data);
    return BuyerNotificationRouteIntent(
      actionType: _readDataText(data, 'action_type'),
      actionPayload: actionPayload,
      eventType: _readDataText(data, 'event_type').isNotEmpty
          ? _readDataText(data, 'event_type')
          : _readDataText(data, 'type'),
      notificationId: _readDataText(data, 'notification_id'),
      storeId: _readDataText(data, 'store_id'),
    );
  }

  Map<String, dynamic> _readPayloadMap(Map<String, dynamic> data) {
    final rawPayload = data['action_payload'] ?? data['actionPayload'];
    if (rawPayload is Map) {
      return rawPayload.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    if (rawPayload is String && rawPayload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map) {
          return decoded.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        // Ignore non-JSON action payloads.
      }
    }

    return <String, dynamic>{
      if (_readDataText(data, 'order_id').isNotEmpty)
        'order_id': _readDataText(data, 'order_id'),
      if (_readDataText(data, 'status').isNotEmpty)
        'status': _readDataText(data, 'status'),
      if (_readDataText(data, 'entity_id').isNotEmpty)
        'entity_id': _readDataText(data, 'entity_id'),
    };
  }

  int _notificationId(RemoteMessage message) {
    final messageId = message.messageId?.trim() ?? '';
    final notificationId = _readDataText(message.data, 'notification_id');
    final source = messageId.isNotEmpty
        ? messageId
        : notificationId.isNotEmpty
        ? notificationId
        : DateTime.now().microsecondsSinceEpoch.toString();
    return source.hashCode & 0x7fffffff;
  }

  String _readDataText(Map<String, dynamic> data, String key) {
    return data[key]?.toString().trim() ?? '';
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}
