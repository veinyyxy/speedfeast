import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A&W Order List Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.grey[50], // Light grey background for the whole page
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const OrderListPage(),
    );
  }
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  // Sample data for order items
  final List<OrderItem> _orderItems = [
    OrderItem(
      id: '1',
      name: 'BLT Chicken Cruncher',
      quantity: 1,
      price: 11.49,
      imagePath: 'assets/images/hamberger1.jpg',
    ),
    OrderItem(
      id: '2',
      name: 'Chubby Chicken® Burger',
      quantity: 1,
      price: 8.69,
      imagePath: 'assets/images/hamberger2.jpg',
    ),
  ];

  double _tipPercentage = 0; // 0 for no tip selected
  double _customTip = 0.0;
  TextEditingController _customTipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customTipController.addListener(_updateCustomTip);
  }

  @override
  void dispose() {
    _customTipController.removeListener(_updateCustomTip);
    _customTipController.dispose();
    super.dispose();
  }

  void _updateCustomTip() {
    final value = double.tryParse(_customTipController.text);
    setState(() {
      _customTip = value ?? 0.0;
      _tipPercentage = -1; // Indicate custom tip is active
    });
  }

  void _updateQuantity(String id, int delta) {
    setState(() {
      final index = _orderItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _orderItems[index].quantity += delta;
        if (_orderItems[index].quantity <= 0) {
          _orderItems.removeAt(index);
        }
      }
    });
  }

  double get subtotal {
    return _orderItems.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  double get deliveryFee => 4.25;
  double get deliveryServiceFee => 2.02;
  double get taxes => subtotal * 0.13; // Example 13% tax

  double get tipAmount {
    if (_tipPercentage == -1) { // Custom tip
      return _customTip;
    } else if (_tipPercentage > 0) {
      return subtotal * _tipPercentage;
    }
    return 0.0;
  }

  double get total {
    return subtotal + deliveryFee + deliveryServiceFee + taxes + tipAmount;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          onPressed: () {
            // Handle back/close
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('0000', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(' pts', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const Text(
              'YOUR BAG',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            // Placeholder for right icon if any
            const SizedBox(width: 48), // To balance the leading icon space
          ],
        ),
        centerTitle: false, // Ensure title alignment is not centered by default
        toolbarHeight: 60, // Adjust height if needed
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Fish Alert
            Container(
              color: Colors.red[100],
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fish Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                        Text(
                          'During this time, our food may contain or come in contact with fish.',
                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Delivery Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Delivery', style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('630 Guelph Street', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Winnipeg, MB, Canada, R3M 3B2',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('Change', style: TextStyle(color: Colors.deepOrange)),
                                  ),
                                  const Icon(Icons.edit, color: Colors.deepOrange, size: 20),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Arriving in 23 minutes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildExpandableInfoCard(
                    title: 'Delivery Details',
                    subtitle: '* Required',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _buildExpandableInfoCard(
                    title: 'Your Information',
                    subtitle: 'Ethan Yang, yainjuyangs@gmail.com',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Order Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: _orderItems.map((item) => _buildOrderItem(item)).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  // Handle Add More Items
                  print('Add More Items tapped');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Add More Items',
                        style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Supply Chain Shortages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Supply Chain Shortages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                          Text(
                            'Some ingredients and items may be unavailable due to delayed shipments or shortages.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tip Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leave a Tip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '100% goes to your delivery driver.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTipButton('15%', subtotal * 0.15, 0.15),
                      _buildTipButton('18%', subtotal * 0.18, 0.18),
                      _buildTipButton('20%', subtotal * 0.20, 0.20),
                      _buildCustomTipButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Price Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                  _buildPriceRow('Delivery Service Fee', '\$${deliveryServiceFee.toStringAsFixed(2)}'),
                  _buildPriceRow('Taxes', '\$${taxes.toStringAsFixed(2)}'),
                  _buildPriceRow('Tip', '\$${tipAmount.toStringAsFixed(2)}'),
                  const Divider(height: 30, thickness: 1, color: Colors.grey),
                  _buildPriceRow(
                    'Total',
                    '\$${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expires /', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('* Required', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '© 2023 A&W Food Services of Canada Inc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Space before bottom button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            // Handle Make My Order
            print('Make My Order - \$${total.toStringAsFixed(2)} tapped');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Make My Order • \$${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableInfoCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell( // Use InkWell for ripple effect on tap
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10), // Margin between items
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(item.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1x ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      _updateQuantity(item.id, -item.quantity); // Remove item
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Remove', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                ],
              ),
            ),
            Text('\$${(item.quantity * item.price).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Row(
              children: [
                _buildQuantityButton(Icons.remove, () => _updateQuantity(item.id, -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _buildQuantityButton(Icons.add, () => _updateQuantity(item.id, 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: Colors.grey[700]),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTipButton(String label, double amount, double percentage) {
    bool isSelected = _tipPercentage == percentage;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipPercentage = percentage;
            _customTipController.clear();
            _customTip = 0.0; // Reset custom tip
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.deepOrange : Colors.black,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.deepOrange : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipButton() {
    bool isSelected = _tipPercentage == -1; // -1 indicates custom tip
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipPercentage = -1; // Activate custom tip
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Custom',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.deepOrange : Colors.black,
                ),
              ),
              SizedBox(
                width: 60, // Limit width of TextField
                child: TextField(
                  controller: _customTipController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  enabled: isSelected, // Only enabled when custom is selected
                  decoration: InputDecoration(
                    hintText: '\$0.00',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.deepOrange.withOpacity(0.7) : Colors.grey[400],
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.deepOrange : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Data model for order items
class OrderItem {
  final String id;
  final String name;
  int quantity;
  final double price;
  final String imagePath;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imagePath,
  });
}