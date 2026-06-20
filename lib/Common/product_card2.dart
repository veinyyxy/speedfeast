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
  final bool isAvailable;
  final String unavailableLabel;

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
    this.isAvailable = true,
    this.unavailableLabel = 'Unavailable',
  });

  @override
  Widget build(BuildContext context) {
    // 检查 imageUrl 是否有效（不为 null 且不为空）
    final bool hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = isAvailable
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.46);
    final secondaryColor = isAvailable
        ? Colors.grey[700]
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final imageOpacity = isAvailable ? 1.0 : 0.38;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isAvailable ? null : Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(fontSize: 16, color: secondaryColor),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isAvailable
                                  ? Colors.grey[600]
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.34,
                                    ),
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
                          color: hasValidImage
                              ? Colors.transparent
                              : Colors.grey[200],
                        ),
                        clipBehavior: Clip.antiAlias,
                        // CONDITIONALLY render Image.network or a placeholder
                        child: Opacity(
                          opacity: imageOpacity,
                          child: hasValidImage
                              ? Image.network(
                                  imageUrl!, // 确保 URL 不为 null
                                  fit: BoxFit.cover,
                                  // 加载构建器：在图片加载时显示进度条
                                  loadingBuilder:
                                      (
                                        BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                  // 错误构建器：在图片加载失败时显示一个错误图标
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        );
                                      },
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ), // 当 imageUrl 无效时显示
                        ),
                      ),
                      if (!isAvailable)
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              unavailableLabel,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (isAvailable)
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
