import 'package:flutter/material.dart';

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
            icon: Icons.credit_card, // Credit card icon
            title: 'Credit or debit card',
            onTap: () {
              print('Credit or debit card tapped');
              // Navigate to credit/debit card details page
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 0), // Divider for visual separation

          _buildPaymentMethodItem(
            context,
            icon: Icons.paypal, // PayPal icon (Note: this icon might look slightly different than the image's custom PayPal logo)
            title: 'PayPal',
            onTap: () {
              print('PayPal tapped');
              // Navigate to PayPal linking page
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 0),

          _buildPaymentMethodItem(
            context,
            icon: Icons.card_giftcard, // Gift card icon
            title: 'Gift card',
            onTap: () {
              print('Gift card tapped');
              // Navigate to gift card entry page
            },
          ),
          // No divider after the last item based on the image
        ],
      ),
    );
  }

  // Helper method to build a consistent payment method list item
  Widget _buildPaymentMethodItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return InkWell( // Use InkWell for a ripple effect on tap
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]), // Icon on the left
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