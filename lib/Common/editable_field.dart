import 'package:flutter/material.dart';

class EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isLocked;
  final bool obscureText; // 添加一个参数用于控制是否隐藏文本

  const EditableField({
    super.key,
    required this.label,
    required this.controller,
    this.isLocked = false,
    this.obscureText = false, // 默认不隐藏
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 1),
                TextField(
                  controller: controller,
                  enabled: !isLocked,
                  obscureText: obscureText,
                  // 使用传入的 obscureText 参数
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey[700] : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: obscureText && controller.text.isEmpty
                        ? '********'
                        : null, // 仅在隐藏且无文本时显示提示
                  ),
                ),
              ],
            ),
          ),
          if (isLocked) Icon(Icons.lock, color: Colors.grey[600]),
        ],
      ),
    );
  }
}