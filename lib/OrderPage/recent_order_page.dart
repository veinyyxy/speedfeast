import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recent Orders',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[800]),
          labelMedium: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
      home: RecentOrdersPage(),
    );
  }
}

class RecentOrdersPage extends StatefulWidget {
  const RecentOrdersPage({super.key});

  @override
  State<RecentOrdersPage> createState() => _RecentOrdersPageState();
}

class _RecentOrdersPageState extends State<RecentOrdersPage> {
  // 模拟订单数据
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-12345',
      'date': '2023-10-15',
      'status': 'Delivered',
      'totalAmount': 150.99,
      'itemCount': 3,
      'shippingAddress': '123 Main St, City, Country',
      'paymentMethod': 'Credit Card',
      'estimatedDelivery': '2023-10-20',
      'actualDelivery': '2023-10-18',
      'items': [
        {'name': 'Product A', 'quantity': 1, 'price': 50.00},
        {'name': 'Product B', 'quantity': 2, 'price': 50.495},
      ],
    },
    {
      'id': 'ORD-67890',
      'date': '2023-10-10',
      'status': 'Shipped',
      'totalAmount': 89.99,
      'itemCount': 1,
      'shippingAddress': '456 Elm St, City, Country',
      'paymentMethod': 'PayPal',
      'estimatedDelivery': '2023-10-15',
      'actualDelivery': null,
      'items': [
        {'name': 'Product C', 'quantity': 1, 'price': 89.99},
      ],
    },
    {
      'id': 'ORD-11223',
      'date': '2023-10-05',
      'status': 'Pending',
      'totalAmount': 200.00,
      'itemCount': 4,
      'shippingAddress': '789 Oak St, City, Country',
      'paymentMethod': 'Bank Transfer',
      'estimatedDelivery': '2023-10-12',
      'actualDelivery': null,
      'items': [
        {'name': 'Product D', 'quantity': 4, 'price': 50.00},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Orders'),
        centerTitle: true,
      ),
      body: _orders.isEmpty
          ? Center(
        child: Text(
          'No recent orders found.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return OrderCard(order: order);
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Shipped':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 订单基本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order['id']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${order['date']}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              'Total: \$${order['totalAmount'].toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Items: ${order['itemCount']}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            // 物品列表（简要显示）
            Text(
              'Items:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ...order['items'].map<Widget>((item) => Text(
              '- ${item['name']} x ${item['quantity']} (\$${item['price'].toStringAsFixed(2)})',
              style: Theme.of(context).textTheme.bodyMedium,
            )),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            // 其他信息
            Text(
              'Shipping Address: ${order['shippingAddress']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Payment Method: ${order['paymentMethod']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Estimated Delivery: ${order['estimatedDelivery']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (order['actualDelivery'] != null)
              Text(
                'Actual Delivery: ${order['actualDelivery']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            SizedBox(height: 16),
            // 操作按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // 查看详情逻辑
                    print('View details for ${order['id']}');
                  },
                  child: Text('View Details'),
                ),
                if (order['status'] == 'Pending')
                  ElevatedButton(
                    onPressed: () {
                      // 取消订单逻辑
                      print('Cancel order ${order['id']}');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Cancel Order'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    // 重新购买逻辑
                    print('Re-order ${order['id']}');
                  },
                  child: Text('Re-order'),
                ),
                if (order['status'] == 'Delivered')
                  ElevatedButton(
                    onPressed: () {
                      // 评价订单逻辑
                      print('Rate order ${order['id']}');
                    },
                    child: Text('Rate Order'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    // 跟踪订单逻辑
                    print('Track order ${order['id']}');
                  },
                  child: Text('Track Order'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 联系客服逻辑
                    print('Contact support for ${order['id']}');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text('Contact Support'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}