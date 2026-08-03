class BuyerStore {
  const BuyerStore({
    required this.storeId,
    required this.storeCode,
    required this.slug,
    required this.name,
    required this.address,
    required this.timezone,
    required this.currency,
    required this.isDefault,
    this.phone,
    this.latitude,
    this.longitude,
  });

  factory BuyerStore.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    final profile = rawProfile is Map
        ? rawProfile.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final rawProfileAddress = profile['address'];
    final rawAddress = rawProfileAddress is Map
        ? rawProfileAddress
        : json['address'];
    return BuyerStore(
      storeId: json['store_id']?.toString().trim() ?? '',
      storeCode: json['store_code']?.toString().trim() ?? '',
      slug: json['slug']?.toString().trim() ?? '',
      name: profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString().trim()
          : json['name']?.toString().trim() ?? '',
      phone: _nullableText(profile['phone']) ?? _nullableText(json['phone']),
      address: rawAddress is Map
          ? rawAddress.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const {},
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      timezone: json['timezone']?.toString().trim() ?? 'America/Winnipeg',
      currency: json['currency']?.toString().trim().toUpperCase() ?? 'CAD',
      isDefault: json['is_default'] == true,
    );
  }

  final String storeId;
  final String storeCode;
  final String slug;
  final String name;
  final String? phone;
  final Map<String, dynamic> address;
  final double? latitude;
  final double? longitude;
  final String timezone;
  final String currency;
  final bool isDefault;

  String get addressDisplay {
    final display = address['display']?.toString().trim() ?? '';
    if (display.isNotEmpty) return display;
    return [
          address['line1'],
          address['city'],
          address['region'],
          address['postal_code'] ?? address['postalCode'],
        ]
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');
  }
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}
