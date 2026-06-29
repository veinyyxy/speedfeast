import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_card.dart';
import 'product_card2.dart';
import 'product_detail.dart';
import '../Controller/service_provider.dart';
import 'order_item.dart';

enum ProductListCardLayout { horizontalList, verticalGrid }

// Product list layout switch for testing.
// horizontalList uses ProductCard2 in a single-column list.
// verticalGrid uses ProductCard in a multi-column grid.
const ProductListCardLayout productListCardLayout =
    //ProductListCardLayout.verticalGrid;
      ProductListCardLayout.horizontalList;
const int productListGridColumnCount = 3;
const double productListGridImageHeight = 104;
const double productListGridItemHeight = 206;

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

  Widget _buildCategoryHeader(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final itemLabel = items.length == 1 ? '1 item' : '${items.length} items';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryColor.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      itemLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: primaryColor.withValues(alpha: 0.22),
            ),
          ],
        ),
      ),
    );
  }

  int get _safeGridColumnCount {
    if (productListGridColumnCount < 1) return 1;
    if (productListGridColumnCount > 4) return 4;
    return productListGridColumnCount;
  }

  OrderItem _baseOrderItem(Product2ItemData item, int quantity) {
    return OrderItem(
      id: item.id,
      productId: item.id,
      name: item.name,
      quantity: quantity,
      price: item.basePrice,
      imagePath: item.imageUrl ?? 'assets/images/hamberger2.jpg',
      description: item.description,
    );
  }

  int _cartQuantity(ServiceProvider serviceProvider, Product2ItemData item) {
    return serviceProvider.cartItems
        .where((cartItem) => cartItem.productId == item.id)
        .fold<int>(0, (sum, cartItem) => sum + cartItem.quantity);
  }

  void _setBaseItemQuantity(
    ServiceProvider serviceProvider,
    Product2ItemData item,
    int count,
  ) {
    if (!item.isAvailable) return;
    serviceProvider.setCartItemQuantity(_baseOrderItem(item, count), count);
  }

  Widget _buildProductCard2List(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: primaryColor.withValues(alpha: 0.22),
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final serviceProvider = context.watch<ServiceProvider>();
        final cartQuantity = _cartQuantity(serviceProvider, item);
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
          onQuantityChanged: (count) =>
              _setBaseItemQuantity(serviceProvider, item, count),
          onTap: () => _openProductDetail(context, item),
        );
      },
    );
  }

  Widget _buildProductCardGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _safeGridColumnCount,
          mainAxisExtent: productListGridItemHeight,
          crossAxisSpacing: 4,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final serviceProvider = context.watch<ServiceProvider>();
          final cartQuantity = _cartQuantity(serviceProvider, item);
          final footerColor = item.isAvailable
              ? Colors.grey.shade800
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

          return ProductCard(
            imagePath: item.imageUrl ?? 'assets/images/hamberger2.jpg',
            width: double.infinity,
            height: productListGridImageHeight,
            framed: false,
            initialCartCount: cartQuantity,
            isAvailable: item.isAvailable,
            unavailableLabel: item.unavailableLabel,
            onImageTap: () => _openProductDetail(context, item),
            onQuantityChanged: (count) =>
                _setBaseItemQuantity(serviceProvider, item, count),
            descriptions: [
              TextDescription(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: item.isAvailable
                      ? const Color(0xFF1F2937)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.46),
                ),
              ),
              TextDescription(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  color: item.isAvailable
                      ? Colors.grey.shade600
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.34),
                ),
              ),
            ],
            footer: Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: footerColor,
                    ),
                  ),
                ),
                if (item.ratingCount > 0) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: item.isAvailable
                        ? Colors.amber.shade700
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${item.ratingAverage.toStringAsFixed(1)} (${item.ratingCount})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: footerColor,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

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
        _buildCategoryHeader(context),
        if (productListCardLayout == ProductListCardLayout.verticalGrid)
          _buildProductCardGrid(context)
        else
          _buildProductCard2List(context),
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
