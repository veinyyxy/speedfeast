import 'dart:convert';

class BuyerNotification {
  const BuyerNotification({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.actionType,
    required this.actionPayload,
    required this.payload,
    required this.isRead,
    required this.createdAt,
    this.readAt = '',
  });

  final String id;
  final String eventType;
  final String title;
  final String body;
  final String actionType;
  final Map<String, dynamic> actionPayload;
  final Map<String, dynamic> payload;
  final bool isRead;
  final String createdAt;
  final String readAt;

  String get displayTitle => title.isNotEmpty ? title : 'SpeedFeast';

  String get displayBody =>
      body.isNotEmpty ? body : 'You have a new notification.';

  String get orderId {
    final value =
        actionPayload['order_id'] ??
        actionPayload['orderId'] ??
        payload['order_id'] ??
        payload['orderId'];
    return value?.toString().trim() ?? '';
  }

  factory BuyerNotification.fromJson(Map<String, dynamic> json) {
    return BuyerNotification(
      id: _readText(json, const ['notification_id', 'notificationId', 'id']),
      eventType: _readText(json, const ['event_type', 'eventType', 'type']),
      title: _readText(json, const ['title']),
      body: _readText(json, const ['body', 'message']),
      actionType: _readText(json, const ['action_type', 'actionType']),
      actionPayload: _readMap(json, const ['action_payload', 'actionPayload']),
      payload: _readMap(json, const ['payload', 'data']),
      isRead: _readBool(json, const ['is_read', 'isRead', 'read']),
      readAt: _readText(json, const ['read_at', 'readAt']),
      createdAt: _readText(json, const ['created_at', 'createdAt', 'sent_at']),
    );
  }
}

class BuyerNotificationRouteIntent {
  const BuyerNotificationRouteIntent({
    required this.actionType,
    required this.actionPayload,
    required this.eventType,
    this.notificationId = '',
  });

  final String actionType;
  final Map<String, dynamic> actionPayload;
  final String eventType;
  final String notificationId;

  factory BuyerNotificationRouteIntent.fromNotification(
    BuyerNotification notification,
  ) {
    return BuyerNotificationRouteIntent(
      actionType: notification.actionType,
      actionPayload: notification.actionPayload,
      eventType: notification.eventType,
      notificationId: notification.id,
    );
  }

  factory BuyerNotificationRouteIntent.fromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const BuyerNotificationRouteIntent(
        actionType: '',
        actionPayload: {},
        eventType: '',
      );
    }
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return const BuyerNotificationRouteIntent(
        actionType: '',
        actionPayload: {},
        eventType: '',
      );
    }
    final data = decoded.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    return BuyerNotificationRouteIntent(
      actionType: _readText(data, const ['action_type', 'actionType']),
      actionPayload: _readMap(data, const ['action_payload', 'actionPayload']),
      eventType: _readText(data, const ['event_type', 'eventType', 'type']),
      notificationId: _readText(data, const [
        'notification_id',
        'notificationId',
      ]),
    );
  }

  String toPayload() {
    return jsonEncode({
      'action_type': actionType,
      'action_payload': actionPayload,
      'event_type': eventType,
      'notification_id': notificationId,
    });
  }
}

String _readText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
  }
  return false;
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        // Ignore non-JSON payloads.
      }
    }
  }
  return const {};
}
