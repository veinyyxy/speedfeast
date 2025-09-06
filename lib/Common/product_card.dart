import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'expandable_cart_button.dart'; // 导入新的按钮组件

// 定义一个简单的类来表示文本描述及其样式
class TextDescription {
  final String text;
  final TextStyle? style; // 允许为每个文本项自定义样式

  TextDescription(this.text, {this.style});
}

class ProductCard extends StatefulWidget { // 保持 StatefulWidget 以便处理回调或需要自身状态
  final String imagePath;
  final List<TextDescription> descriptions;
  final VoidCallback? onImageTap;
  final double? width;
  final double? height;
  final Function(int count)? onQuantityChanged; // 父组件关心的数量变化
  final int initialCartCount; // 新增：传递给按钮的初始数量

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.descriptions,
    this.onImageTap,
    required this.width,
    required this.height,
    this.onQuantityChanged,
    this.initialCartCount = 0, // 默认为0
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,        children: [
        Stack(
          children: [
            GestureDetector(
              onTap: widget.onImageTap ??
                      () {
                    if (kDebugMode) {
                      print('Image tapped: ${widget.imagePath}');
                    }
                  },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.imagePath,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: ExpandableCartButton(
                heroTagPrefix: widget.imagePath, // 使用 imagePath 作为 heroTag 前缀
                initialCount: widget.initialCartCount,
                onQuantityChanged: (count) {
                  // setState(() { // 如果ProductCard自身需要根据count更新UI
                  //   _currentCartCount = count;
                  // });
                  // 将数量变化通知给 ProductCard 的父组件
                  widget.onQuantityChanged?.call(count);
                  if (kDebugMode) {
                    print('Quantity for ${widget.imagePath} changed to: $count');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...widget.descriptions.map((desc) {
          final defaultTextStyle = DefaultTextStyle.of(context).style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              desc.text,
              style: desc.style ?? defaultTextStyle,
            ),
          );
        }),
      ],
      ),
    );
  }
}
