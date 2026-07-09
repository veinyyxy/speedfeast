import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  const UserPreferences({
    this.version = 1,
    this.updatedAt = '',
    this.preferences = const {},
  });

  factory UserPreferences.empty() {
    return const UserPreferences();
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final rawPreferences = json['preferences'];
    return UserPreferences(
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      updatedAt: json['updated_at']?.toString() ?? '',
      preferences: rawPreferences is Map
          ? rawPreferences.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const {},
    );
  }

  final int version;
  final String updatedAt;
  final Map<String, dynamic> preferences;

  String get fulfillmentType {
    final home = _section('home');
    return _normalizeFulfillmentType(
      home['fulfillment_type']?.toString() ?? '',
    );
  }

  RecentOrdersPreferences get recentOrders {
    return RecentOrdersPreferences.fromJson(_section('recent_orders'));
  }

  UserPreferences copyWithFulfillmentType(String fulfillmentType) {
    final nextPreferences = _copyPreferences();
    final home = _copySection(nextPreferences, 'home');
    home['fulfillment_type'] = _normalizeFulfillmentType(fulfillmentType);
    nextPreferences['home'] = home;
    return _copyWithPreferences(nextPreferences);
  }

  UserPreferences copyWithRecentOrders({
    required String dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final nextPreferences = _copyPreferences();
    final recentOrders = _copySection(nextPreferences, 'recent_orders');
    recentOrders['date_filter'] = _normalizeRecentOrdersDateFilter(dateFilter);

    final hasCustomRange = customStart != null && customEnd != null;
    if (hasCustomRange) {
      recentOrders['custom_range'] = {
        'start': _formatDate(customStart),
        'end': _formatDate(customEnd),
      };
    } else if (!recentOrders.containsKey('custom_range')) {
      recentOrders['custom_range'] = null;
    }

    nextPreferences['recent_orders'] = recentOrders;
    return _copyWithPreferences(nextPreferences);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'updated_at': updatedAt,
      'preferences': preferences,
    };
  }

  Map<String, dynamic> _section(String name) {
    final value = preferences[name];
    if (value is! Map) return const {};
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  Map<String, dynamic> _copyPreferences() {
    return _deepCopyMap(preferences);
  }

  Map<String, dynamic> _copySection(Map<String, dynamic> source, String name) {
    final value = source[name];
    if (value is! Map) return <String, dynamic>{};
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), _deepCopyValue(value)),
    );
  }

  UserPreferences _copyWithPreferences(Map<String, dynamic> nextPreferences) {
    return UserPreferences(
      version: version,
      updatedAt: DateTime.now().toIso8601String(),
      preferences: nextPreferences,
    );
  }
}

class RecentOrdersPreferences {
  const RecentOrdersPreferences({
    this.dateFilter = 'all',
    this.customStart,
    this.customEnd,
  });

  factory RecentOrdersPreferences.fromJson(Map<String, dynamic> json) {
    final customRangeValue = json['custom_range'];
    final customRange = customRangeValue is Map
        ? customRangeValue.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    return RecentOrdersPreferences(
      dateFilter: _normalizeRecentOrdersDateFilter(
        json['date_filter']?.toString() ?? '',
      ),
      customStart: _parseDate(customRange['start']),
      customEnd: _parseDate(customRange['end']),
    );
  }

  final String dateFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
}

class UserPreferencesStore {
  const UserPreferencesStore._();

  static const guestStorageKey = 'speedfeast_user_preferences_v1_guest';
  static const userStoragePrefix = 'speedfeast_user_preferences_v1_';

  static String storageKeyForUserId(String? userId) {
    final normalized = userId?.trim() ?? '';
    if (normalized.isEmpty) return guestStorageKey;
    return '$userStoragePrefix$normalized';
  }

  static Future<UserPreferences> load(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return UserPreferences.empty();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return UserPreferences.empty();
      return UserPreferences.fromJson(
        decoded.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } catch (_) {
      return UserPreferences.empty();
    }
  }

  static Future<void> save(
    String storageKey,
    UserPreferences preferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(preferences.toJson()));
  }
}

String _normalizeFulfillmentType(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'dine_in' => 'dine_in',
    'takeout' || 'take_out' => 'takeout',
    _ => 'delivery',
  };
}

String _normalizeRecentOrdersDateFilter(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'today' => 'today',
    'three_days' || '3_days' => 'three_days',
    'one_week' || '1_week' || 'week' => 'one_week',
    'custom' => 'custom',
    _ => 'all',
  };
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
  return source.map<String, dynamic>(
    (key, value) => MapEntry(key, _deepCopyValue(value)),
  );
}

dynamic _deepCopyValue(dynamic value) {
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), _deepCopyValue(value)),
    );
  }
  if (value is List) {
    return value.map(_deepCopyValue).toList(growable: false);
  }
  return value;
}

DateTime? _parseDate(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
