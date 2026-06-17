import 'package:flutter/material.dart';

class AddPaymentMethodPage extends StatelessWidget {
  const AddPaymentMethodPage({super.key});

  void _openPaymentList(BuildContext context, String type) {
    Navigator.pushReplacementNamed(
      context,
      '/more_page/payment_options/payment_list',
      arguments: {'open': type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add a payment method'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildPaymentMethodItem(
            context,
            icon: Icons.credit_card,
            title: 'Credit or debit card',
            onTap: () => _openPaymentList(context, 'card'),
          ),
          const Divider(indent: 16, endIndent: 16, height: 0),
          _buildPaymentMethodItem(
            context,
            icon: Icons.paypal,
            title: 'PayPal',
            onTap: () => _openPaymentList(context, 'paypal'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Icon(icon, size: 24, color: Colors.deepOrange),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
