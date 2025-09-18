import 'package:flutter/material.dart';
import 'home_page_exclusive2.dart';
import 'OrderPage/order_list_page.dart';
import 'OrderPage/recent_order_page.dart';
import 'MoreMenu/more_main_menu.dart';
import 'MoreMenu/more_my_account_personal_info.dart';
import 'Payment/add_payment_method.dart';
import 'Payment/payment_list_page.dart';

void main() {
  runApp(
      MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // 将主色调改为 DeepOrange
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white, // Pure white background
        appBarTheme: const AppBarTheme(
          // AppBar 背景色改为 DeepOrange
          backgroundColor: Colors.white70,
          elevation: 0, // No shadow for app bar
          // AppBar 图标颜色改为白色，与 DeepOrange 背景形成对比
          iconTheme: IconThemeData(color: Colors.deepOrange),
          titleTextStyle: TextStyle(
            // AppBar 标题文字颜色改为白色
            color: Colors.deepOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.deepOrange),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.deepOrange,
            //minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.deepOrange,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepOrange,
            side: const BorderSide(color: Colors.deepOrange, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        )
        // 如果你需要按钮、浮动操作按钮等也使用 DeepOrange
        // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange),
      ),
      routes: {
        '/': (context) => HomePage(),
        '/order_page': (context) => OrderListPage(),
        '/order_page/recent_orders': (context) => RecentOrdersPage(),
        '/more_page': (context) => MoreMainMenu(),
        '/more_page/personal_info': (context) => PersonalInfoPage(),
        '/more_page/payment_options': (context) => AddPaymentMethodPage(),
        '/more_page/payment_options/payment_list': (context) => PaymentListPage(),
      },
      initialRoute: '/',
    );
  }
 /* @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Item Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Menu Items'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Example with image (Paneer Paratha)
            ProductCard2(
              name: 'Paneer Paratha',
              price: 'CA\$5.99',
              description: 'Indian-style flatbread stuffed with paneer.',
              imageUrl: 'assets/images/cat.jpg', // Replace with your image asset
              initialCount: 0,
              onQuantityChanged: (count) => print("'Paneer Paratha' $count."),
              onTap: () {
                print('Tapped on Paneer Paratha item');
              },
            ),
            const SizedBox(height: 20),
            // Example without image (Aloo Tikki Noodle Kathi Roll)
            ProductCard2(
              name: 'Aloo Tikki Noodle Kathi Roll',
              price: 'CA\$10.99',
              description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
              initialCount: 0,
              onQuantityChanged: (count) => print("'Aloo Tikki Noodle Kathi Roll' $count."),
              onTap: () {
                print('Tapped on Aloo Tikki Noodle Kathi Roll item');
              },
            ),
            const SizedBox(height: 20),
            // Another example with image
            ProductCard2(
              name: 'Butter Chicken',
              price: 'CA\$15.50',
              description:
              'Tender chicken pieces cooked in a rich, creamy tomato sauce with aromatic spices. Served with a side of basmati rice.',
              imageUrl: 'assets/images/iphone15.jpg', // Replace with your image asset
              initialCount: 0,
              onQuantityChanged: (count) => print("'Butter Chicken' $count."),
              onTap: () {
                print('Tapped on Butter Chicken item');
              },
            ),
            const SizedBox(height: 20),
            // Another example without image (long description)
            ProductCard2(
              name: 'Vegetable Samosa',
              price: 'CA\$3.50',
              description:
              'Crispy pastry filled with spiced potatoes and peas. A classic Indian appetizer that\'s perfect for sharing or as a quick snack.',
              initialCount: 0,
              onQuantityChanged: (count) => print("'Vegetable Samosa' $count."),
              onTap: () {
                print('Tapped on Vegetable Samosa item');
              },
            ),
          ],
        ),
      ),
    );
  }*/
}