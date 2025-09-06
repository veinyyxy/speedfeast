import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'product_card.dart'; // 确保这个路径是正确的

class ProductItemData {
  final String imagePath;
  final String brandName;
  final String productName;
  final String price;

  ProductItemData({
    required this.imagePath,
    required this.brandName,
    required this.productName,
    required this.price,
  });
}

class HorizontalScrollSection extends StatefulWidget {
  final String title;
  final List<ProductItemData> items; // 使用数据模型列表，而不是简单的图片路径列表
  final VoidCallback? onViewMore; // 添加一个“查看更多”的回调函数

  const HorizontalScrollSection({
    super.key,
    required this.title,
    required this.items,
    this.onViewMore,
  });

  @override
  State<HorizontalScrollSection> createState() => _HorizontalScrollSectionState();
}

class _HorizontalScrollSectionState extends State<HorizontalScrollSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;
  static const double _scrollStep = 200.0; // 每次滚动的步长

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始状态判断是否显示右侧按钮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkButtonVisibility();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      _checkButtonVisibility();
    }
  }

  void _checkButtonVisibility() {
    // 确保 scroller 已经附加并且有维度信息
    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) {
      // 如果ListView是空的或者还没有渲染，两个按钮都不显示
      setState(() {
        _showLeftButton = false;
        _showRightButton = false;
      });
      return;
    }

    setState(() {
      _showLeftButton = _scrollController.offset > 0;
      _showRightButton = _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + _scrollStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - _scrollStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有项目，可以显示一个空状态或者直接不显示
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 如果提供了回调函数，就显示右箭头按钮
              if (widget.onViewMore != null)
                InkWell(
                  onTap: widget.onViewMore,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.chevron_right),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            SizedBox(
              height: 220, // 你可以根据ProductCard的高度进行调整
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // 给ListView一些内边距
                itemBuilder: (context, index) {
                  final item = widget.items[index];

                  // 从数据模型构建描述
                  final productDescriptions = [
                    TextDescription(
                      item.brandName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextDescription(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextDescription(
                      item.price,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                  ];

                  // 为每个卡片添加右边距，除了最后一个
                  return Padding(
                    padding: EdgeInsets.only(right: index == widget.items.length - 1 ? 0 : 12.0),
                    child: ProductCard(
                      imagePath: item.imagePath,
                      descriptions: productDescriptions,
                      onQuantityChanged: (count) {
                        if (kDebugMode) {
                          print('${item.productName} quantity changed to: $count');
                        }
                      },
                      width: 150, // 定义卡片的宽度
                      height: 150, // 定义图片的高度
                    ),
                  );
                },
              ),
            ),
            // 左边按钮
            if (_showLeftButton)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 30, color: Colors.black87),
                      onPressed: _scrollLeft,
                    ),
                  ),
                ),
              ),
            // 右边按钮
            if (_showRightButton)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 30, color: Colors.black87),
                      onPressed: _scrollRight,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}