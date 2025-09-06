import 'package:flutter/material.dart';

class BusinessItemWidget extends StatefulWidget {
  final String businessName;
  final String imageUrl;
  final bool isFavorite; // 是否收藏
  final double rating; // 评分
  final String deliveryTime; // 配送时间，例如 "10 min"
  final String deliveryFee; // 配送费，例如 "$0.99 Delivery Fee"

  const BusinessItemWidget({
    super.key,
    required this.businessName,
    required this.imageUrl,
    this.isFavorite = false, // 默认不收藏
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
  });

  @override
  State<BusinessItemWidget> createState() => _BusinessItemWidgetState();
}

class _BusinessItemWidgetState extends State<BusinessItemWidget> {
  late bool _isFavorite; // 内部状态来管理收藏

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite; // 初始化内部状态
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      // 在这里可以添加将收藏状态保存到后端或本地存储的逻辑
      print('${widget.businessName} Favorite status: $_isFavorite');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0, // 无阴影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 广告图片和收藏按钮
          Stack(
            children: [
              // 广告图片
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  widget.imageUrl, // 使用 Image.network 加载网络图片
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 图片加载失败时的占位符
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              // 收藏按钮
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha:0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.black : Colors.grey, // 收藏为黑色实心，否则为灰色边框
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 商家名称和评分/配送信息
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.businessName, // 商家名称
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange[400], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      widget.rating.toStringAsFixed(1), // 评分，保留一位小数
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.timer, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      widget.deliveryTime, // 配送时间
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.delivery_dining, color: Colors.grey, size: 18), // 配送图标
                    const SizedBox(width: 4),
                    Text(
                      widget.deliveryFee, // 配送费用
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}