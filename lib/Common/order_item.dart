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

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imagePath,
    String? productId,
    this.description = '',
    this.selectedOptions = const {},
  }) : productId = productId ?? id;

  double get subtotal => quantity * price;

  ImageProvider resolveImageProvider() {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }
    return AssetImage(imagePath);
  }
}
