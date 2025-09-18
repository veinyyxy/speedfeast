import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add Payment Method',
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
        // 如果你需要按钮、浮动操作按钮等也使用 DeepOrange
        // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange),
      ),
      home: const AddPaymentMethodPage(),
    );
  }
}

class AddPaymentMethodPage extends StatelessWidget {
  const AddPaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back arrow icon
          onPressed: () {
            // Handle back button press
            Navigator.of(context).pop(); // Example: pop the current route
          },
        ),
        title: const Text('Add a payment method'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Some vertical padding for the list
        children: [
          _buildPaymentMethodItem(
            context,
            iconWidget: Icon(Icons.credit_card, size: 24, /*color: Colors.grey[700]*/),
            title: 'Credit or debit card',
            onTap: () {
              print('Credit or debit card tapped');
              // Navigate to credit/debit card details page
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 0), // Divider for visual separation

          _buildPaymentMethodItem(
            context,
            iconWidget: Icon(Icons.paypal, size: 24, /*color: Colors.grey[700]*/),
            title: 'PayPal',
            onTap: () {
              print('PayPal tapped');
              // Navigate to PayPal linking page
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 0),

          // --- 新增 Google Pay ---
          _buildPaymentMethodItem(
            context,
            iconWidget: FaIcon(FontAwesomeIcons.googlePay, size: 24, /*color: Colors.grey[700]*/),
            title: 'Google Pay',
            onTap: () {
              print('Google Pay tapped');
              // Navigate to Google Pay linking page
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 0),

          // --- 新增 Apple Pay ---
          _buildPaymentMethodItem(
            context,
            iconWidget: FaIcon(FontAwesomeIcons.applePay, size: 24, /*color: Colors.grey[700]*/),
            title: 'Apple Pay',
            onTap: () {
              print('Apple Pay tapped');
              // Navigate to Apple Pay linking page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
      BuildContext context, {
        required Widget iconWidget,
        required String title,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 16.0), // Spacing between icon and text
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  /*color: Colors.black,*/ // 列表项文字颜色保持黑色，或根据需要调整
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, /*color: Colors.grey*/), // Right arrow icon
          ],
        ),
      ),
    );
  }
}