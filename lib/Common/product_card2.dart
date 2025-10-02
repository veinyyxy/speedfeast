import 'package:flutter/material.dart';
import 'expandable_cart_button.dart'; // 确保这个文件存在

class ProductCard2 extends StatelessWidget {
  final String id;
  final String name;
  final String price;
  final String description;
  final String? imageUrl; // imageUrl 可以是 null
  final int initialCount;
  final Function(int count) onQuantityChanged;
  final VoidCallback onTap;

  const ProductCard2({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl, // 允许 imageUrl 为 null
    required this.initialCount,
    required this.onQuantityChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 检查 imageUrl 是否有效（不为 null 且不为空）
    final bool hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 根据 imageUrl 的有效性来显示图片或占位符
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          // 如果没有有效图片，显示一个默认图标
                          color: hasValidImage ? Colors.transparent : Colors.grey[200],
                        ),
                        // CONDITIONALLY render Image.network or a placeholder
                        child: hasValidImage
                            ? Image.network(
                          imageUrl!, // 确保 URL 不为 null
                          fit: BoxFit.cover,
                          // 加载构建器：在图片加载时显示进度条
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          // 错误构建器：在图片加载失败时显示一个错误图标
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                          },
                        )
                            : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey), // 当 imageUrl 无效时显示
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: ExpandableCartButton(
                          initialCount: initialCount,
                          onQuantityChanged: onQuantityChanged,
                          heroTagPrefix: name,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}