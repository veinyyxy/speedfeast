import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'expandable_cart_button.dart'; // 导入新的按钮组件

// 定义一个简单的类来表示文本描述及其样式
class TextDescription {
  final String text;
  final TextStyle? style; // 允许为每个文本项自定义样式

  TextDescription(this.text, {this.style});
}

class ProductCard extends StatefulWidget {
  // 保持 StatefulWidget 以便处理回调或需要自身状态
  final String imagePath;
  final List<TextDescription> descriptions;
  final VoidCallback? onImageTap;
  final double? width;
  final double? height;
  final Function(int count)? onQuantityChanged; // 父组件关心的数量变化
  final int initialCartCount; // 新增：传递给按钮的初始数量
  final bool framed;
  final bool isAvailable;
  final String unavailableLabel;
  final Widget? footer;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.descriptions,
    this.onImageTap,
    required this.width,
    required this.height,
    this.onQuantityChanged,
    this.initialCartCount = 0, // 默认为0
    this.framed = false,
    this.isAvailable = true,
    this.unavailableLabel = 'Unavailable',
    this.footer,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // 如果 ProductCard 本身不需要直接跟踪 itemCount 来改变其他非按钮UI，
  // 这里的 _itemCount 和相关方法可以被移除，完全依赖 ExpandableCartButton
  // 但如果 ProductCard 需要知道数量，例如传递给更上层的组件，则保留
  // int _currentCartCount;

  // @override
  // void initState() {
  //   super.initState();
  //   _currentCartCount = widget.initialCartCount;
  // }

  Widget _buildProductImage() {
    final source = widget.imagePath.trim();
    final imageOpacity = widget.isAvailable ? 1.0 : 0.38;

    Widget image;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      image = Image.network(
        source,
        width: double.infinity,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
      );
    } else {
      image = Image.asset(
        source.isEmpty ? 'assets/images/hamberger2.jpg' : source,
        width: double.infinity,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
      );
    }

    return Opacity(opacity: imageOpacity, child: image);
  }

  Widget _buildImageFallback() {
    return Container(
      width: double.infinity,
      height: widget.height,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: widget.framed ? const EdgeInsets.all(5.0) : EdgeInsets.zero,
      decoration: widget.framed
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap:
                    widget.onImageTap ??
                    () {
                      if (kDebugMode) {
                        print('Image tapped: ${widget.imagePath}');
                      }
                    },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildProductImage(),
                ),
              ),
              if (!widget.isAvailable)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
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
                      widget.unavailableLabel,
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
              if (widget.isAvailable)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: ExpandableCartButton(
                    heroTagPrefix:
                        widget.imagePath, // 使用 imagePath 作为 heroTag 前缀
                    initialCount: widget.initialCartCount,
                    onQuantityChanged: (count) {
                      // setState(() { // 如果ProductCard自身需要根据count更新UI
                      //   _currentCartCount = count;
                      // });
                      // 将数量变化通知给 ProductCard 的父组件
                      widget.onQuantityChanged?.call(count);
                      if (kDebugMode) {
                        print(
                          'Quantity for ${widget.imagePath} changed to: $count',
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
          SizedBox(height: widget.framed ? 3 : 4),
          ...widget.descriptions.map((desc) {
            final defaultTextStyle = DefaultTextStyle.of(context).style;
            final textStyle = desc.style ?? defaultTextStyle;
            return Padding(
              padding: EdgeInsets.only(bottom: widget.framed ? 1.0 : 2.0),
              child: Text(
                desc.text,
                style: widget.framed
                    ? textStyle.copyWith(height: 1.1)
                    : textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}
