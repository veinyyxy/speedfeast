import 'package:flutter/material.dart';
import 'product_card2.dart'; // 使用你给的ProductCard2类

class ProductCategoryList extends StatelessWidget {
  final String categoryName;
  final List<Product2ItemData> items;

  const ProductCategoryList({
    super.key,
    required this.categoryName,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类名标题
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

        // 商品列表
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // 让外层可滚动
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ProductCard2(
              name: item.name,
              price: item.price,
              description: item.description,
              imageUrl: item.imageUrl,
              initialCount: 0,
              onQuantityChanged: (count) {
                debugPrint('${item.name} 数量: $count');
              },
              onTap: () {
                debugPrint('点击了 ${item.name}');
              },
            );
          },
        ),
      ],
    );
  }
}

// 用于承载商品数据的模型
class Product2ItemData {
  final String name;
  final String price;
  final String description;
  final String? imageUrl;

  Product2ItemData({
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
  });
}
