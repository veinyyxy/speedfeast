import 'package:flutter/material.dart';
import 'home_page_exclusive.dart';
import 'Common/product_card2.dart';

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
  }
 /* @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RewardsScreen(),
    );
  }*/


}