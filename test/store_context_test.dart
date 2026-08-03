import 'package:flutter_test/flutter_test.dart';
import 'package:speedfeast/Common/store_context.dart';
import 'package:speedfeast/Notifications/buyer_notification_models.dart';

void main() {
  test('buyer store parses identity, location and currency', () {
    final store = BuyerStore.fromJson({
      'store_id': 'store-id',
      'store_code': 'NORTH',
      'slug': 'north',
      'name': 'obsolete table value',
      'profile': {
        'name': 'North Store',
        'phone': '204-555-0100',
        'address': {
          'line1': '100 Profile Street',
          'city': 'Winnipeg',
          'region': 'MB',
        },
      },
      'phone': '204-555-0199',
      'address': {
        'line1': '100 Main Street',
        'city': 'Winnipeg',
        'region': 'MB',
      },
      'latitude': '49.8951',
      'longitude': -97.1384,
      'currency': 'cad',
      'is_default': true,
    });

    expect(store.storeId, 'store-id');
    expect(store.name, 'North Store');
    expect(store.phone, '204-555-0100');
    expect(store.addressDisplay, '100 Profile Street, Winnipeg, MB');
    expect(store.latitude, 49.8951);
    expect(store.longitude, -97.1384);
    expect(store.currency, 'CAD');
    expect(store.isDefault, isTrue);
  });

  test('buyer notification payload preserves its target store', () {
    const original = BuyerNotificationRouteIntent(
      actionType: 'open_order',
      actionPayload: {'order_id': 'order-id'},
      eventType: 'order_status_changed',
      notificationId: 'notification-id',
      storeId: 'store-id',
    );

    final restored = BuyerNotificationRouteIntent.fromPayload(
      original.toPayload(),
    );

    expect(restored.storeId, 'store-id');
    expect(restored.notificationId, 'notification-id');
    expect(restored.actionPayload['order_id'], 'order-id');
  });
}
