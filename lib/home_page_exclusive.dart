import 'package:flutter/material.dart';
import 'Common/reward_widget.dart';
import 'Common/product_category_list.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  /*final List<ProductItemData> productItems1 = [
    ProductItemData(imagePath: 'assets/images/pears.jpg', brandName: 'Fresh Farms', productName: 'Juicy Pears', price: '300 pts'),
    ProductItemData(imagePath: 'assets/images/watermelon.jpg', brandName: 'Green Valley', productName: 'Sweet Watermelon', price: '300 pts'),
    ProductItemData(imagePath: 'assets/images/carrots.jpg', brandName: 'Organic+', productName: 'Crisp Carrots', price: '300 pts'),
  ];

  final List<ProductItemData> productItems2 = [
    ProductItemData(imagePath: 'assets/images/carrots.jpg', brandName: 'Organic+', productName: 'Crisp Carrots', price: '1500 pts'),
    ProductItemData(imagePath: 'assets/images/cat.jpg', brandName: 'Pet Food Co.', productName: 'Happy Cat Kibble', price: '1500 pts'),
    ProductItemData(imagePath: 'assets/images/radish.jpg', brandName: 'Farm Fresh', productName: 'Spicy Radish', price: '1500 pts'),
    ProductItemData(imagePath: 'assets/images/cherries.jpg', brandName: 'Sweet Treats', productName: 'Ripe Cherries', price: '1500 pts'),
  ];*/
  final kathiRolls1 = [
    Product2ItemData(
      name: "Aloo Tikki Noodle Kathi Roll",
      price: "CA\$10.99",
      description: "Crispy potato patties wrapped in a flavorful noodle wrap.",
    ),
    Product2ItemData(
      name: "Paneer Tikka Kathi Roll",
      price: "CA\$10.99",
      description: "Marinated paneer in a creamy tomato sauce wrapped in a soft tortilla.",
    ),
    Product2ItemData(
      name: "Chicken Tikka Kathi Roll",
      price: "CA\$11.99",
      description: "Tender chicken in a creamy tomato-based wrap.",
    ),
  ];

  final kathiRolls2 = [
    Product2ItemData(
      name: 'Paneer Paratha',
      price: 'CA\$5.99',
      description: 'Indian-style flatbread stuffed with paneer.',
      imageUrl: 'assets/images/cat.jpg', // Replace with your image asset
    ),
    Product2ItemData(
      name: 'Aloo Tikki Noodle Kathi Roll',
      price: 'CA\$10.99',
      description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
    ),
    Product2ItemData(
      name: 'Aloo Tikki Noodle Kathi Roll',
      price: 'CA\$10.99',
      description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/images/log.png'),
        backgroundColor: Colors.blueAccent,
        actions: [
          // 使用 Padding 在文字右侧添加一些间距，防止它紧贴屏幕边缘
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center( // 使用 Center 确保文字在垂直方向上居中
              child: const Text(
                'SpeedFeast',
                style: TextStyle(color: Colors.black, fontSize: 40),
                // textAlign 在这里不再需要，因为 Text 的宽度就是文字本身的宽度
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
            children: [
              const RewardWidget(),
              const SizedBox(height: 16),
              ProductCategoryList(
                categoryName: "Kathi Rolls",
                items: kathiRolls1,
              ),
              const SizedBox(height: 16),
              ProductCategoryList(
                categoryName: "Kathi Rolls",
                items: kathiRolls2,
              ),
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
