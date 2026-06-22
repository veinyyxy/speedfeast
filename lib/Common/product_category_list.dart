import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_card2.dart';
import 'product_detail.dart';
import '../Controller/service_provider.dart';
import 'order_item.dart';

class ProductCategoryList extends StatelessWidget {
  final String categoryName;
  final List<Product2ItemData> items;
  final String storeName;

  const ProductCategoryList({
    super.key,
    required this.categoryName,
    required this.items,
    this.storeName = 'SpeedFeast Restaurant',
  });

  void _openProductDetail(BuildContext context, Product2ItemData item) {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} is currently unavailable.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final serviceProvider = context.read<ServiceProvider>();
    final cartQuantity = serviceProvider.cartItems
        .where((cartItem) => cartItem.productId == item.id)
        .fold<int>(0, (sum, cartItem) => sum + cartItem.quantity);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductDetail(
          id: item.id,
          name: item.name,
          description: item.description,
          storeName: storeName,
          imageProvider: item.resolveImageProvider(),
          basePrice: item.basePrice,
          ratingAverage: item.ratingAverage,
          ratingCount: item.ratingCount,
          initialQuantity: cartQuantity > 0 ? cartQuantity : 1,
          optionGroups: item.optionGroups,
          onAddToOrder: (orderData) {
            final optionParts =
                orderData.selections.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .map((entry) {
                      final values = entry.value.toList()..sort();
                      return '${entry.key}:${values.join(",")}';
                    })
                    .toList()
                  ..sort();
            final optionsKey = optionParts.join('|');
            final specialInstructions = orderData.specialInstructions.trim();
            final specialInstructionsKey = specialInstructions.isEmpty
                ? ''
                : 'note:${Uri.encodeComponent(specialInstructions)}';
            final itemKeyParts = [
              if (optionsKey.isNotEmpty) optionsKey,
              if (specialInstructionsKey.isNotEmpty) specialInstructionsKey,
            ];
            final orderItem = OrderItem(
              id: itemKeyParts.isEmpty
                  ? item.id
                  : '${item.id}|${itemKeyParts.join("|")}',
              productId: item.id,
              name: item.name,
              quantity: orderData.quantity,
              price: orderData.unitPrice,
              imagePath: item.imageUrl ?? 'assets/images/hamberger2.jpg',
              description: item.description,
              selectedOptions: orderData.selections,
              specialInstructions: specialInstructions,
            );

            if (itemKeyParts.isEmpty) {
              serviceProvider.setCartItemQuantity(
                orderItem,
                orderData.quantity,
              );
            } else {
              serviceProvider.addToCart(orderItem);
            }

            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added ${orderData.quantity} x ${item.name} to order',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            categoryName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final serviceProvider = context.watch<ServiceProvider>();
            final cartQuantity = serviceProvider.cartItems
                .where((cartItem) => cartItem.productId == item.id)
                .fold<int>(0, (sum, cartItem) => sum + cartItem.quantity);
            return ProductCard2(
              id: item.id,
              name: item.name,
              price: item.displayPrice,
              description: item.description,
              imageUrl: item.imageUrl,
              initialCount: cartQuantity,
              isAvailable: item.isAvailable,
              unavailableLabel: item.unavailableLabel,
              ratingAverage: item.ratingAverage,
              ratingCount: item.ratingCount,
              onQuantityChanged: (count) {
                if (!item.isAvailable) {
                  return;
                }
                serviceProvider.setCartItemQuantity(
                  OrderItem(
                    id: item.id,
                    productId: item.id,
                    name: item.name,
                    quantity: count,
                    price: item.basePrice,
                    imagePath: item.imageUrl ?? 'assets/images/hamberger2.jpg',
                    description: item.description,
                  ),
                  count,
                );
              },
              onTap: () => _openProductDetail(context, item),
            );
          },
        ),
      ],
    );
  }
}

class Product2ItemData {
  final String id;
  final String name;
  final String price;
  final String description;
  final String? imageUrl;
  final String status;
  final double ratingAverage;
  final int ratingCount;
  final List<ProductDetailOptionGroup> optionGroups;

  Product2ItemData({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
    this.status = 'active',
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.optionGroups = const [],
  });

  factory Product2ItemData.fromJson(
    Map<String, dynamic> json, {
    String imageRoot = '',
  }) {
    final productId = json['product_id']?.toString() ?? '';
    final rawImageUrl = json['image_url']?.toString();
    final imageUrl = rawImageUrl == null || rawImageUrl.isEmpty
        ? null
        : rawImageUrl.startsWith('http://') ||
              rawImageUrl.startsWith('https://') ||
              rawImageUrl.startsWith('assets/')
        ? rawImageUrl
        : '$imageRoot$rawImageUrl';

    return Product2ItemData(
      id: productId,
      name:
          json['product_name']?.toString() ??
          json['name']?.toString() ??
          'Unnamed product',
      price: json['base_price']?.toString() ?? json['price']?.toString() ?? '0',
      description: json['description']?.toString() ?? '',
      imageUrl: imageUrl,
      status:
          (json['status']?.toString() ??
                  json['product_status']?.toString() ??
                  'active')
              .trim()
              .toLowerCase(),
      ratingAverage: _firstDouble(json, const [
        'rating_average',
        'ratingAverage',
        'average_rating',
        'averageRating',
      ]),
      ratingCount: _firstInt(json, const [
        'rating_count',
        'ratingCount',
        'review_count',
        'reviewCount',
      ]),
      optionGroups: ProductDetailOptionGroup.listFromJson(
        json['option_groups'] ?? json['optionGroups'],
      ),
    );
  }

  double get basePrice {
    final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String get displayPrice {
    if (price.contains(r'$')) return price;
    final value = basePrice;
    return 'CA\$${value.toStringAsFixed(2)}';
  }

  bool get isAvailable => status == 'active';

  String get unavailableLabel {
    if (status == 'inactive') {
      return 'Temporarily unavailable';
    }
    if (status == 'archived') {
      return 'Unavailable';
    }
    return 'Unavailable';
  }

  ImageProvider resolveImageProvider() {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        return AssetImage(url);
      }
      return NetworkImage(url);
    }
    return const AssetImage('assets/images/hamberger2.jpg');
  }
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is String && value.trim().isEmpty) continue;
    return value;
  }
  return null;
}

double _firstDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toDouble();
  final text = value?.toString() ?? '';
  final normalized = text.replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(normalized) ?? 0;
}

int _firstInt(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
