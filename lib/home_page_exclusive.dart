import 'package:flutter/material.dart';
import 'Common/reward_widget.dart';
import 'Common/horizontal_scroll_section.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final List<ProductItemData> productItems1 = [
    ProductItemData(imagePath: 'assets/images/pears.jpg', brandName: 'Fresh Farms', productName: 'Juicy Pears', price: '300 pts'),
    ProductItemData(imagePath: 'assets/images/watermelon.jpg', brandName: 'Green Valley', productName: 'Sweet Watermelon', price: '300 pts'),
    ProductItemData(imagePath: 'assets/images/carrots.jpg', brandName: 'Organic+', productName: 'Crisp Carrots', price: '300 pts'),
  ];

  final List<ProductItemData> productItems2 = [
    ProductItemData(imagePath: 'assets/images/carrots.jpg', brandName: 'Organic+', productName: 'Crisp Carrots', price: '1500 pts'),
    ProductItemData(imagePath: 'assets/images/cat.jpg', brandName: 'Pet Food Co.', productName: 'Happy Cat Kibble', price: '1500 pts'),
    ProductItemData(imagePath: 'assets/images/radish.jpg', brandName: 'Farm Fresh', productName: 'Spicy Radish', price: '1500 pts'),
    ProductItemData(imagePath: 'assets/images/cherries.jpg', brandName: 'Sweet Treats', productName: 'Ripe Cherries', price: '1500 pts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                  children: const [
                    Text(
                      'Viewing items for Pickup at:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      '1875 Pembina Highway, Win...', // Or 867 Waverley Street...
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(width: 8), // 地址文本和圆形按钮之间的间距
                RawMaterialButton( // 圆形编辑按钮
                  onPressed: () {
                    // Handle edit location
                  },
                  elevation: 0, // 默认不显示阴影
                  fillColor: Colors.deepOrange.shade50, // 按钮背景色，这里使用一个浅橙色
                  shape: const CircleBorder(), // 设置为圆形
                  constraints: BoxConstraints.tightFor(width: 40.0, height: 40.0), // 固定按钮尺寸
                  child: const Icon(Icons.edit, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
            children: [
              const RewardWidget(),
              const SizedBox(height: 16),
              HorizontalScrollSection(title: 'productItems1', items: productItems1),
              const SizedBox(height: 16),
              HorizontalScrollSection(title: 'productItems2', items: productItems2),
            ]
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
