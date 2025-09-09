import 'package:flutter/material.dart';

// ================= NEW: 定义支付卡片类型和数据模型 =================
enum CardType { visa, mastercard, unionpay, paypal, googlepay, applepay }

class PaymentInfo {
  final CardType cardType;
  final String lastFourDigits;
  final String expiryDate;

  PaymentInfo({
    required this.cardType,
    required this.lastFourDigits,
    required this.expiryDate,
  });
}
// ====================================================================

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
        scaffoldBackgroundColor: Colors.grey[50],
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

enum DeliveryMode { delivery, dineIn, takeout }

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
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

  double _tipPercentage = 0;
  double _customTip = 0.0;
  final TextEditingController _customTipController = TextEditingController();

  bool _isAddItemButtonPressed = false;
  bool _showCustomTipInput = false;
  DeliveryMode _deliveryMode = DeliveryMode.delivery;

  // ================= NEW: 添加支付信息状态变量 =================
  PaymentInfo? _paymentInfo; // null 表示没有支付信息
  // ==========================================================

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

  // ================= NEW: 模拟添加支付信息的方法 =================
  void _addDummyPaymentInfo() {
    setState(() {
      _paymentInfo = PaymentInfo(
        cardType: CardType.paypal,
        lastFourDigits: '4242',
        expiryDate: '12/25',
      );
    });
  }
  // ==========================================================

  void _updateCustomTip() {
    final value = double.tryParse(_customTipController.text);
    setState(() {
      _customTip = value ?? 0.0;
      _tipPercentage = -1;
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

  double get subtotal => _orderItems.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  double get deliveryFee => 4.25;
  double get deliveryServiceFee => 2.02;
  double get taxes => subtotal * 0.13;

  double get tipAmount {
    if (_tipPercentage == -1) {
      return _customTip;
    } else if (_tipPercentage > 0) {
      return subtotal * _tipPercentage;
    }
    return 0.0;
  }

  double get total {
    if (_deliveryMode == DeliveryMode.delivery) {
      return subtotal + deliveryFee + deliveryServiceFee + taxes + tipAmount;
    }
    return subtotal + taxes + tipAmount;
  }

  @override
  Widget build(BuildContext context) {
    // 检查是否有支付信息，用于按钮状态
    final bool isPaymentReady = _paymentInfo != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(10.0)),
              child: Row(
                children: [
                  const Text('0000', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(' pts', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const Text('YOUR BAG', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 48),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 60,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            _buildOrderModeSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: _orderItems.map((item) => _buildOrderItem(item)).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => print('Add More Items tapped'),
                onTapDown: (_) => setState(() => _isAddItemButtonPressed = true),
                onTapUp: (_) => setState(() => _isAddItemButtonPressed = false),
                onTapCancel: () => setState(() => _isAddItemButtonPressed = false),
                child: AnimatedScale(
                  scale: _isAddItemButtonPressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text('Add More Items', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leave a Tip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('100% goes to your delivery driver.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                  if (_deliveryMode == DeliveryMode.delivery) ...[
                    _buildPriceRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
                    _buildPriceRow('Delivery Service Fee', '\$${deliveryServiceFee.toStringAsFixed(2)}'),
                  ],
                  _buildPriceRow('Taxes', '\$${taxes.toStringAsFixed(2)}'),
                  _buildPriceRow('Tip', '\$${tipAmount.toStringAsFixed(2)}'),
                  const Divider(height: 30, thickness: 1, color: Colors.grey),
                  _buildPriceRow('Total', '\$${total.toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // ================= MODIFIED: 条件渲染支付信息区域 =================
                  _paymentInfo == null
                      ? _buildAddPaymentCard() // 显示 "添加支付方式"
                      : _buildPaymentInfoCard(_paymentInfo!), // 显示已有的支付信息
                  // ================================================================
                  const SizedBox(height: 10),
                  Text('© 2023 A&W Food Services of Canada Inc.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: ElevatedButton(
          // ================= MODIFIED: 根据支付状态设置按钮 =================
          onPressed: isPaymentReady
              ? () => print('Make My Order - \$${total.toStringAsFixed(2)} tapped')
              : null, // 如果没有支付信息，按钮不可用
          style: ElevatedButton.styleFrom(
            backgroundColor: isPaymentReady ? Colors.deepOrange : Colors.grey[400], // 可用和不可用时的颜色
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          // ===============================================================
          child: Text('Make My Order • \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ================= NEW: 构建 "添加支付方式" 的卡片 =================
  Widget _buildAddPaymentCard() {
    return GestureDetector(
      onTap: _addDummyPaymentInfo, // 点击时模拟添加一张Visa卡
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)), // 文本已修改
                Text('* Required', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= NEW: 构建显示支付信息的卡片 =================
  Widget _buildPaymentInfoCard(PaymentInfo info) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：图标
          _getPaymentIcon(info.cardType),
          const SizedBox(width: 12),
          // 中间：卡片信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•••• ${info.lastFourDigits}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Expires ${info.expiryDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // 右侧：箭头图标
          const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        ],
      ),
    );
  }

  // ================= NEW: 根据卡片类型获取对应图标的辅助函数 =================
  Widget _getPaymentIcon(CardType cardType) {
    String assetName;
    switch (cardType) {
      case CardType.mastercard:
        assetName = 'mastercard.png';
        break;
      case CardType.unionpay:
        assetName = 'unionpay.png';
        break;
      case CardType.paypal:
        assetName = 'paypal.png';
        break;
        case CardType.googlepay:
        assetName = 'googlepay.png';
        break;
      case CardType.applepay:
        assetName = 'applepay.png';
        break;
      default:
        assetName = 'visa.png'; // 默认图标
    }
    // 假设您的图标在 'assets/icons/' 目录下
    return Image.asset('assets/icons/$assetName', width: 40);
  }
  // ====================================================================

  // (其余代码保持不变)
  Widget _buildOrderModeSection() {
    String title;
    IconData iconData;
    switch (_deliveryMode) {
      case DeliveryMode.delivery:
        title = 'Delivery';
        iconData = Icons.delivery_dining;
        break;
      case DeliveryMode.dineIn:
        title = 'Dine-in';
        iconData = Icons.restaurant;
        break;
      case DeliveryMode.takeout:
        title = 'Takeout';
        iconData = Icons.shopping_bag;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDeliveryModeSelector(),
                const SizedBox(height: 16),
                _buildConditionalModeContent(),
              ],
            ),
          ),
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(iconData, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeSelector() {
    return Row(
      children: [
        _buildModeButton('Delivery', DeliveryMode.delivery),
        const SizedBox(width: 8),
        _buildModeButton('Dine-in', DeliveryMode.dineIn),
        const SizedBox(width: 8),
        _buildModeButton('Takeout', DeliveryMode.takeout),
      ],
    );
  }

  Widget _buildModeButton(String text, DeliveryMode mode) {
    final isSelected = _deliveryMode == mode;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _deliveryMode = mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.deepOrange : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildConditionalModeContent() {
    switch (_deliveryMode) {
      case DeliveryMode.delivery:
        return _buildDeliveryDetails();
      case DeliveryMode.dineIn:
        return _buildDineInDetails();
      case DeliveryMode.takeout:
        return _buildTakeoutDetails();
    }
  }

  Widget _buildDeliveryDetails() {
    return Column(
      children: [
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
                        Text('Winnipeg, MB, Canada, R3M 3B2', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
      ],
    );
  }

  Widget _buildDineInDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('A&W Restaurant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('630 Guelph Street, Winnipeg, MB, Canada, R3M 3B2', style: TextStyle(color: Colors.grey[700])),
        const Divider(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Table Number', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('12', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildTakeoutDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pickup at A&W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('630 Guelph Street, Winnipeg, MB, Canada, R3M 3B2', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('Ready in 15-20 minutes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableInfoCard({required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
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
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
      margin: const EdgeInsets.only(bottom: 10),
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
                image: DecorationImage(image: AssetImage(item.imagePath), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.quantity}x ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => _updateQuantity(item.id, -item.quantity),
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
      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
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
            _customTip = 0.0;
            _showCustomTipInput = false;
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
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.deepOrange : Colors.black)),
              Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: isSelected ? Colors.deepOrange : Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipButton() {
    bool isSelected = _tipPercentage == -1;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipPercentage = -1;
            _showCustomTipInput = true;
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
              Text('Custom', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.deepOrange : Colors.black)),
              _showCustomTipInput
                  ? SizedBox(
                height: 20,
                child: TextField(
                  controller: _customTipController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '\$0.00',
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(fontSize: 12, color: isSelected ? Colors.deepOrange.withOpacity(0.7) : Colors.grey[400]),
                  ),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.deepOrange : Colors.grey[700]),
                ),
              )
                  : Text(
                _customTip > 0 ? '\$${_customTip.toStringAsFixed(2)}' : ' ',
                style: TextStyle(fontSize: 12, color: isSelected ? Colors.deepOrange : Colors.grey[700]),
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
          Text(label, style: TextStyle(fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.black : Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.black : Colors.black)),
        ],
      ),
    );
  }
}

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