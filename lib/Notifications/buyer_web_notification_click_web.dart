// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool _attached = false;

void attachBuyerWebNotificationClickListener(
  void Function(Map<String, dynamic> data) onData,
) {
  if (_attached) return;
  _attached = true;

  html.window.navigator.serviceWorker?.onMessage.listen((event) {
    final envelope = _asMap(event.data);
    final type = envelope['type']?.toString().trim() ?? '';
    if (type != 'buyer_notification_click') return;
    onData(_asMap(envelope['data']));
  });
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is! Map) return const {};
  return value.map<String, dynamic>(
    (key, value) => MapEntry(key.toString(), value),
  );
}
