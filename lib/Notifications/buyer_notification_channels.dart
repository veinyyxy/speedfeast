import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BuyerNotificationChannels {
  static const orderStatus = 'order_status';
  static const pointsUpdates = 'points_updates';

  static const _pointsEvents = {
    'reward_points_earned',
    'reward_points_redeemed',
    'reward_points_restored',
    'reward_points_adjusted',
  };

  static String resolveChannelId(String eventType) {
    final normalized = eventType.trim().toLowerCase();
    if (_pointsEvents.contains(normalized) ||
        normalized.startsWith('reward_')) {
      return pointsUpdates;
    }
    return orderStatus;
  }

  static AndroidNotificationChannel androidChannel(String channelId) {
    switch (channelId) {
      case pointsUpdates:
        return const AndroidNotificationChannel(
          pointsUpdates,
          'Points Updates',
          description: 'Updates when your points balance changes.',
          importance: Importance.defaultImportance,
        );
      case orderStatus:
      default:
        return const AndroidNotificationChannel(
          orderStatus,
          'Order Status',
          description: 'Updates when your order status changes.',
          importance: Importance.high,
        );
    }
  }

  static List<AndroidNotificationChannel> get androidChannels => const [
    AndroidNotificationChannel(
      orderStatus,
      'Order Status',
      description: 'Updates when your order status changes.',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      pointsUpdates,
      'Points Updates',
      description: 'Updates when your points balance changes.',
      importance: Importance.defaultImportance,
    ),
  ];

  static AndroidNotificationDetails androidDetails(String channelId) {
    final channel = androidChannel(channelId);
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: channelId == orderStatus
          ? Priority.high
          : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
  }

  static DarwinNotificationDetails get darwinDetails =>
      const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
}
