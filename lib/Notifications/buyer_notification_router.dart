import 'package:flutter/material.dart';

import 'buyer_notification_models.dart';

class BuyerNotificationRouter {
  static Future<void> handle(
    GlobalKey<NavigatorState> navigatorKey,
    BuyerNotificationRouteIntent intent,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    await handleWithNavigator(navigator, intent);
  }

  static Future<void> handleWithNavigator(
    NavigatorState navigator,
    BuyerNotificationRouteIntent intent,
  ) async {
    final action = intent.actionType.trim().toLowerCase();
    if (action == 'open_order' || action == 'open_orders') {
      await navigator.pushNamed(
        '/order_page/recent_orders',
        arguments: intent.actionPayload,
      );
      return;
    }

    if (action == 'open_rewards' ||
        action == 'open_reward' ||
        action == 'open_points') {
      await navigator.pushNamed(
        '/more_page/rewards_activity',
        arguments: intent.actionPayload,
      );
      return;
    }

    await navigator.pushNamed(
      '/notifications',
      arguments: intent.actionPayload,
    );
  }
}
