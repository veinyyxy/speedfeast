import 'package:flutter/material.dart';
import 'Common/reward_widget.dart';
import 'Common/product_category_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      id: '1',
      name: "Aloo Tikki Noodle Kathi Roll",
      price: "CA\$10.99",
      description: "Crispy potato patties wrapped in a flavorful noodle wrap.",
    ),
    Product2ItemData(
      id: '2',
      name: "Paneer Tikka Kathi Roll",
      price: "CA\$10.99",
      description: "Marinated paneer in a creamy tomato sauce wrapped in a soft tortilla.",
    ),
    Product2ItemData(
      id: '3',
      name: "Chicken Tikka Kathi Roll",
      price: "CA\$11.99",
      description: "Tender chicken in a creamy tomato-based wrap.",
    ),
  ];

  final kathiRolls2 = [
    Product2ItemData(
      id: '4',
      name: 'Paneer Paratha',
      price: 'CA\$5.99',
      description: 'Indian-style flatbread stuffed with paneer.',
      imageUrl: 'assets/images/cat.jpg', // Replace with your image asset
    ),
    Product2ItemData(
      id: '5',
      name: 'Aloo Tikki Noodle Kathi Roll',
      price: 'CA\$10.99',
      description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
    ),
    Product2ItemData(
      id: '6',
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
        title: Text(
          'SpeedFeast',
          style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(50, 255, 160, 122),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Speed Feast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  )),
              background: Stack( // 使用 Stack 来叠加图片和文字
                children: <Widget>[
                  Image.asset(
                    'assets/images/sushi.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity, // 确保图片宽度填充可用空间
                    height: double.infinity, // 确保图片高度填充可用空间
                  ),
                  Positioned( // 定位文本到底部中间
                    bottom: 20.0, // 距离底部20像素
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 让 Column 尽可能小
                      children: const <Widget>[
                        Text(
                          'Welcome to SpeedFeast Restaurant',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            shadows: [ // 添加文字阴影使其更易读
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.0), // 添加一点垂直间距
                        Text(
                          '体验极速美食与温馨氛围的完美结合，让您的味蕾享受非凡之旅。', // 餐厅介绍
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.0,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return ListTile(
                  title: Text('列表项 $index'),
                );
              },
              childCount: 50,
            ),
          ),
        ],
      ),
      /*SingleChildScrollView(
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
      )*/
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
