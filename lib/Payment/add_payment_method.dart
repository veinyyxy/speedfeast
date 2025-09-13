import 'package:flutter/material.dart';
// 1. 导入 font_awesome_flutter 包
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
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.white, // Pure white background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // White app bar
          elevation: 0, // No shadow for app bar
          iconTheme: IconThemeData(color: Colors.black), // Black back arrow
          titleTextStyle: TextStyle(
            color: Colors.black, // Black title text
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            // 3. 传入完整的 Icon Widget
            iconWidget: Icon(Icons.credit_card, size: 24, color: Colors.grey[700]),
            title: 'Credit or debit card',
            onTap: () {
              print('Credit or debit card tapped');
              // Navigate to credit/debit card details page
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 0), // Divider for visual separation

          _buildPaymentMethodItem(
            context,
            iconWidget: Icon(Icons.paypal, size: 24, color: Colors.grey[700]),
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
            iconWidget: FaIcon(FontAwesomeIcons.googlePay, size: 24, color: Colors.grey[700]),
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
            iconWidget: FaIcon(FontAwesomeIcons.applePay, size: 24, color: Colors.grey[700]),
            title: 'Apple Pay',
            onTap: () {
              print('Apple Pay tapped');
              // Navigate to Apple Pay linking page
            },
          ),
          /*const Divider(indent: 16, endIndent: 16, height: 0),

          _buildPaymentMethodItem(
            context,
            iconWidget: Icon(Icons.card_giftcard, size: 24, color: Colors.grey[700]),
            title: 'Gift card',
            onTap: () {
              print('Gift card tapped');
              // Navigate to gift card entry page
            },
          ),*/
          // No divider after the last item based on the image
        ],
      ),
    );
  }

  // 2. 修改辅助方法，使其接受一个 Widget 类型的 iconWidget，更加灵活
  Widget _buildPaymentMethodItem(
      BuildContext context, {
        required Widget iconWidget, // 修改点：从 IconData 改为 Widget
        required String title,
        required VoidCallback onTap,
      }) {
    return InkWell( // Use InkWell for a ripple effect on tap
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // 使用 SizedBox 确保所有图标占用相同的空间
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
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // Right arrow icon
          ],
        ),
      ),
    );
  }
}