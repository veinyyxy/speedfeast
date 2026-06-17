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
          initialQuantity: cartQuantity > 0 ? cartQuantity : 1,
          optionGroups: const [],
          onAddToOrder: (orderData) {
            final optionsKey = orderData.selections.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) => '${entry.key}:${entry.value.join(",")}')
                .join('|');
            final orderItem = OrderItem(
              id: optionsKey.isEmpty ? item.id : '${item.id}|$optionsKey',
              productId: item.id,
              name: item.name,
              quantity: orderData.quantity,
              price: orderData.unitPrice,
              imagePath: item.imageUrl ?? 'assets/images/hamberger2.jpg',
              description: item.description,
              selectedOptions: orderData.selections,
            );

            if (optionsKey.isEmpty) {
              serviceProvider.setCartItemQuantity(orderItem, orderData.quantity);
            } else {
              serviceProvider.addToCart(orderItem);
            }

            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${orderData.quantity} x ${item.name} to order'),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
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
              onQuantityChanged: (count) {
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

  Product2ItemData({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
  });

  double get basePrice {
    final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String get displayPrice {
    if (price.contains(r'$')) return price;
    final value = basePrice;
    return 'CA\$${value.toStringAsFixed(2)}';
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
