import 'package:flutter/material.dart';

class SelectEditBox extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;       // 整个框体的点击事件，现在用于通知父级我被选中了
  final VoidCallback onIconTap;   // 右侧图标的点击事件
  final String? id;               // 新增：可选的唯一标识符，用于组选择
  final bool isSelected;          // 新增：由父级控制的选中状态

  const SelectEditBox({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    required this.onIconTap,
    this.id,                      // 允许传入 id
    this.isSelected = false,      // 默认不选中
  });

  @override
  State<SelectEditBox> createState() => _SelectEditBoxState();
}

class _SelectEditBoxState extends State<SelectEditBox> {
  // 移除了 bool _isSelected 状态

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 整个框体的点击事件，直接使用 widget.onTap
      // 这个 onTap 将由父级提供，用于更新父级的选中状态
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          // 根据 widget.isSelected 状态改变边框颜色
          border: Border.all(color: widget.isSelected ? Colors.deepOrange : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value.isEmpty ? widget.label : widget.value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: Colors.deepOrange,
              onPressed: widget.onIconTap,
            ),
          ],
        ),
      ),
    );
  }
}