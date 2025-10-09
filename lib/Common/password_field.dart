import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isVisible;
  final Function(bool) onToggle;

  const PasswordField({
    Key? key,
    required this.label,
    required this.controller,
    required this.isVisible,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // 使用Expanded确保TextField占据可用空间
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 1),
                TextField(
                  controller: controller, // 绑定控制器
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    isDense: true, // 使输入框更紧凑
                    contentPadding: EdgeInsets.zero, // 移除默认内边距
                    border: InputBorder.none,
                    hintText: '••••••••',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              onToggle(!isVisible);
            },
          ),
        ],
      ),
    );
  }
}