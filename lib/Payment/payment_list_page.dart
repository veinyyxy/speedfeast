import 'package:flutter/material.dart';
import '../Common/select_edit_box.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaymentListPage(),
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          labelSmall: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.orange),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final List<Map<String, String>> _paymentMethods = [
    {'id': '1', 'label': 'Visa Card', 'value': '**** **** **** 1234'},
    {'id': '2', 'label': 'MasterCard', 'value': '**** **** **** 5678'},
    {'id': '3', 'label': 'PayPal', 'value': 'user@example.com'},
  ];
  String? _selectedPaymentId;

  @override
  void initState() {
    super.initState();
    if (_paymentMethods.isNotEmpty) {
      _selectedPaymentId = _paymentMethods[0]['id'];
    }
  }

  void _selectPayment(String id) {
    setState(() {
      _selectedPaymentId = id;
    });
  }

  void _addPaymentMethod() {
    final newId = (_paymentMethods.length + 1).toString();
    setState(() {
      _paymentMethods.add({
        'id': newId,
        'label': 'New Payment',
        'value': '**** **** **** ${1000 + int.parse(newId)}',
      });
      _selectedPaymentId = newId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added new payment method')),
    );
  }

  void _updateSettings() {
    if (_selectedPaymentId != null) {
      final selectedMethod = _paymentMethods.firstWhere(
            (method) => method['id'] == _selectedPaymentId,
      );
      print('Updated default payment to: ${selectedMethod['label']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings updated: ${selectedMethod['label']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No payment method selected')),
      );
    }
  }

  void _deletePayment(String id) {
    setState(() {
      _paymentMethods.removeWhere((method) => method['id'] == id);
      if (_selectedPaymentId == id) {
        _selectedPaymentId = _paymentMethods.isNotEmpty ? _paymentMethods[0]['id'] : null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment method deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Payment Methods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _paymentMethods.length + 1, // 包含“Add Payment Method”项
                itemBuilder: (context, index) {
                  if (index < _paymentMethods.length) {
                    final method = _paymentMethods[index];
                    return Dismissible(
                      key: Key(method['id']!),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deletePayment(method['id']!);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: SelectEditBox(
                        label: method['label']!,
                        value: method['value']!,
                        id: method['id'],
                        isSelected: _selectedPaymentId == method['id'],
                        onTap: () => _selectPayment(method['id']!),
                        onIconTap: () {
                          print('Edit ${method['label']}');
                        },
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete this address?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    // 最后一个项是“Add Payment Method”按钮
                    return GestureDetector(
                      onTap: _addPaymentMethod,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Payment Method',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor),
                            ),
                            Icon(Icons.add),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateSettings,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}