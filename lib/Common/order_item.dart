import 'package:flutter/material.dart';

class OrderItem {
  final String id;
  final String productId;
  final String name;
  int quantity;
  final double price;
  final String imagePath;
  final String description;
  final Map<String, List<String>> selectedOptions;
  final String specialInstructions;
  final bool isAvailable;
  final String availabilityMessage;
  final bool priceChanged;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imagePath,
    String? productId,
    this.description = '',
    this.selectedOptions = const {},
    this.specialInstructions = '',
    this.isAvailable = true,
    this.availabilityMessage = '',
    this.priceChanged = false,
  }) : productId = productId ?? id;

  double get subtotal => quantity * price;

  ImageProvider resolveImageProvider() {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }
    return AssetImage(imagePath);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'image_path': imagePath,
      'description': description,
      'selected_options': selectedOptions,
      'special_instructions': specialInstructions,
      'is_available': isAvailable,
      'availability_message': availabilityMessage,
      'price_changed': priceChanged,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final id = _readText(json, ['id']);
    final productId = _readText(json, ['product_id', 'productId']);
    final name = _readText(json, ['name']);
    final quantity = _readInt(json['quantity']);
    final price = _readDouble(json['price']);
    final imagePath = _readText(json, ['image_path', 'imagePath']);

    return OrderItem(
      id: id.isEmpty ? productId : id,
      productId: productId.isEmpty ? id : productId,
      name: name,
      quantity: quantity < 1 ? 1 : quantity,
      price: price,
      imagePath: imagePath.isEmpty ? 'assets/images/hamberger2.jpg' : imagePath,
      description: _readText(json, ['description']),
      selectedOptions: _readSelectedOptions(
        json['selected_options'] ?? json['selectedOptions'],
      ),
      specialInstructions: _readText(json, [
        'special_instructions',
        'specialInstructions',
      ]),
      isAvailable: _readBool(json['is_available'] ?? json['isAvailable'], true),
      availabilityMessage: _readText(json, [
        'availability_message',
        'availabilityMessage',
      ]),
      priceChanged: _readBool(json['price_changed'] ?? json['priceChanged']),
    );
  }

  OrderItem copyWith({
    String? id,
    String? productId,
    String? name,
    int? quantity,
    double? price,
    String? imagePath,
    String? description,
    Map<String, List<String>>? selectedOptions,
    String? specialInstructions,
    bool? isAvailable,
    String? availabilityMessage,
    bool? priceChanged,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isAvailable: isAvailable ?? this.isAvailable,
      availabilityMessage: availabilityMessage ?? this.availabilityMessage,
      priceChanged: priceChanged ?? this.priceChanged,
    );
  }

  static String _readText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static bool _readBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return defaultValue;
  }

  static Map<String, List<String>> _readSelectedOptions(dynamic value) {
    if (value is! Map) return const {};

    final options = <String, List<String>>{};
    for (final entry in value.entries) {
      final key = entry.key?.toString() ?? '';
      if (key.isEmpty) continue;

      final rawValues = entry.value;
      if (rawValues is List) {
        options[key] = rawValues
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
      } else {
        final text = rawValues?.toString().trim() ?? '';
        options[key] = text.isEmpty ? <String>[] : <String>[text];
      }
    }

    return options;
  }
}
