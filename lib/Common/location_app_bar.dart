// lib/Common/location_app_bar.dart

import 'package:flutter/material.dart';

class LocationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String locationName;
  final VoidCallback onEditLocationPressed;

  const LocationAppBar({
    super.key,
    required this.locationName,
    required this.onEditLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orangeAccent,
      elevation: 0,
      leading: Image.asset('assets/images/log.png'), // Replace with your A&W logo
      title: Align( // 外层Align用于将整个包裹的Container靠右
        alignment: Alignment.centerRight,
        child: Container( // 整个右侧地址和按钮的大框
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 边框内部的间距
          decoration: BoxDecoration(
            color: Colors.orange[50], // 整个大框的背景色
            border: Border.all(color: Colors.grey.shade400, width: 1), // 整个大框的灰色边框
            borderRadius: BorderRadius.circular(10), // 可选：圆角边框
          ),
          child: Row( // 使用Row来水平排列地址Column和圆形按钮
            mainAxisSize: MainAxisSize.min, // 让Row占据最小的水平空间
            children: [
              Column( // 地址文本Column
                crossAxisAlignment: CrossAxisAlignment.end, // Column内部文本依然靠右
                mainAxisSize: MainAxisSize.min, // 让Column占据最小的水平空间
                children: [
                  const Text(
                    'Viewing items for Pickup at:',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    locationName, // 使用传入的地址参数
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    overflow: TextOverflow.ellipsis, // 防止文本过长溢出
                  ),
                ],
              ),
              const SizedBox(width: 8), // 地址文本和圆形按钮之间的间距
              RawMaterialButton( // 圆形编辑按钮
                onPressed: onEditLocationPressed, // 使用传入的回调函数
                elevation: 0, // 默认不显示阴影
                fillColor: Colors.deepOrange.shade50, // 按钮背景色，这里使用一个浅橙色
                shape: const CircleBorder(), // 设置为圆形
                constraints: const BoxConstraints.tightFor(width: 40.0, height: 40.0), // 固定按钮尺寸
                child: const Icon(Icons.edit, color: Colors.deepOrange),
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}