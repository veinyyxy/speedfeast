import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import '../RegisterPage/phone_login_page.dart';

class RecentOrdersPage extends StatefulWidget {
  const RecentOrdersPage({super.key});

  @override
  State<RecentOrdersPage> createState() => _RecentOrdersPageState();
}

class _RecentOrdersPageState extends State<RecentOrdersPage> {
  Future<List<RecentOrder>>? _ordersFuture;
  bool? _lastLoginState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLoggedIn = context.watch<ServiceProvider>().isLoggedIn;
    if (_lastLoginState == isLoggedIn) return;

    _lastLoginState = isLoggedIn;
    _ordersFuture = isLoggedIn ? _fetchOrders() : null;
  }

  Future<List<RecentOrder>> _fetchOrders() async {
    final rawOrders = await context.read<ServiceProvider>().fetchRecentOrders();
    return rawOrders.map(RecentOrder.fromJson).toList(growable: false);
  }

  Future<void> _reloadOrders() async {
    final future = _fetchOrders();
    setState(() {
      _ordersFuture = future;
    });
    await future;
  }

  Future<void> _showLoginDialog() async {
    final result = await showLoginDialog(context);
    if (!mounted) return;
    if (result == true) {
      await _reloadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<ServiceProvider>().isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'RECENT ORDERS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (isLoggedIn)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _reloadOrders,
            ),
        ],
      ),
      body: isLoggedIn ? _buildOrdersBody() : _buildSignedOutState(),
    );
  }

  Widget _buildOrdersBody() {
    return FutureBuilder<List<RecentOrder>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ScrollableStateMessage(
            icon: Icons.error_outline,
            title: 'Orders could not be loaded',
            message: snapshot.error.toString(),
            buttonLabel: 'Try Again',
            onPressed: _reloadOrders,
          );
        }

        final orders = snapshot.data ?? [];
        final providerError =
            context.read<ServiceProvider>().lastRecentOrdersError;
        if (orders.isEmpty && providerError != null) {
          return _ScrollableStateMessage(
            icon: Icons.wifi_off_outlined,
            title: 'Orders could not be loaded',
            message: providerError,
            buttonLabel: 'Try Again',
            onPressed: _reloadOrders,
          );
        }

        if (orders.isEmpty) {
          return _ScrollableStateMessage(
            icon: Icons.receipt_long_outlined,
            title: 'No recent orders',
            message: 'Orders you place will appear here with their status.',
            buttonLabel: 'Refresh',
            onPressed: _reloadOrders,
          );
        }

        return RefreshIndicator(
          onRefresh: _reloadOrders,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSignedOutState() {
    return _ScrollableStateMessage(
      icon: Icons.lock_outline,
      title: 'Sign in to view order status',
      message:
          'Your recent orders and delivery progress are linked to your account.',
      buttonLabel: 'Sign In',
      onPressed: _showLoginDialog,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final RecentOrder order;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.dateLabel,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(label: order.status, color: color),
              ],
            ),
            const SizedBox(height: 16),
            _StatusTimeline(order: order),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.shopping_bag_outlined,
              label: '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.payments_outlined,
              label: 'CAD \$${order.totalAmount.toStringAsFixed(2)}',
            ),
            if (order.fulfillmentLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.storefront_outlined,
                label: order.fulfillmentLabel,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showOrderDetails(context, order),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, RecentOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order});

  final RecentOrder order;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomPadding),
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.displayId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(
                  label: order.status,
                  color: _statusColor(order.status),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailRow(label: 'Status', value: order.status),
            _DetailRow(label: 'Date', value: order.dateLabel),
            _DetailRow(label: 'Fulfillment', value: order.fulfillmentLabel),
            _DetailRow(label: 'Payment', value: order.paymentMethod),
            _DetailRow(
              label: 'Estimated Delivery',
              value: order.estimatedDelivery,
            ),
            _DetailRow(label: 'Delivered', value: order.actualDelivery),
            _DetailRow(label: 'Address', value: order.shippingAddress),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (order.items.isEmpty)
              Text(
                'No item details available.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...order.items.map((item) => _OrderItemLine(item: item)),
          ],
        ),
      ),
    );
  }
}

class _OrderItemLine extends StatelessWidget {
  const _OrderItemLine({required this.item});

  final RecentOrderItem item;

  @override
  Widget build(BuildContext context) {
    final price =
        item.price > 0 ? 'CAD \$${item.price.toStringAsFixed(2)}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${item.quantity}x ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (price.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(price, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order});

  final RecentOrder order;

  @override
  Widget build(BuildContext context) {
    final rank = _statusRank(order.status);
    if (rank < 0) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This order is ${order.status.toLowerCase()}.',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      );
    }

    final steps = order.isDelivery
        ? const ['Placed', 'Preparing', 'On the way', 'Delivered']
        : const ['Placed', 'Preparing', 'Ready', 'Completed'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++)
          Expanded(
            child: _TimelineStep(
              label: steps[index],
              isComplete: index <= rank,
              isCurrent: index == rank,
            ),
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isComplete,
    required this.isCurrent,
  });

  final String label;
  final bool isComplete;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? Colors.deepOrange : Colors.grey.shade400;
    final icon = isCurrent
        ? Icons.radio_button_checked
        : isComplete
            ? Icons.check_circle
            : Icons.circle_outlined;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollableStateMessage extends StatelessWidget {
  const _ScrollableStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
      children: [
        Icon(icon, size: 48, color: Colors.grey.shade500),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 22),
        Center(
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class RecentOrder {
  const RecentOrder({
    required this.id,
    required this.status,
    required this.dateLabel,
    required this.totalAmount,
    required this.itemCount,
    required this.fulfillmentType,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.estimatedDelivery,
    required this.actualDelivery,
    required this.items,
  });

  final String id;
  final String status;
  final String dateLabel;
  final double totalAmount;
  final int itemCount;
  final String fulfillmentType;
  final String shippingAddress;
  final String paymentMethod;
  final String estimatedDelivery;
  final String actualDelivery;
  final List<RecentOrderItem> items;

  String get displayId => id.isEmpty ? 'Order' : 'Order #$id';

  bool get isDelivery => fulfillmentType.toLowerCase().contains('delivery');

  String get fulfillmentLabel => _humanize(fulfillmentType);

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    final items = _readList(
      json,
      const ['items', 'order_items', 'orderItems', 'products'],
    ).map(RecentOrderItem.fromJson).toList(growable: false);
    final dateLabel = _formatDate(
      _firstValue(
        json,
        const ['created_at', 'createdAt', 'order_date', 'orderDate', 'date'],
      ),
    );

    return RecentOrder(
      id: _firstString(
        json,
        const ['order_id', 'orderId', 'order_no', 'orderNumber', 'id'],
      ),
      status: _humanize(
        _firstString(
          json,
          const ['status', 'order_status', 'orderStatus', 'current_status'],
          fallback: 'Pending',
        ),
      ),
      dateLabel: dateLabel.isEmpty ? 'Date unavailable' : dateLabel,
      totalAmount: _firstDouble(
        json,
        const ['total_amount', 'totalAmount', 'grand_total', 'total', 'amount'],
      ),
      itemCount: _firstInt(
        json,
        const ['item_count', 'itemCount', 'total_items', 'totalItems'],
        fallback: items.fold<int>(0, (sum, item) => sum + item.quantity),
      ),
      fulfillmentType: _firstString(
        json,
        const ['fulfillment_type', 'fulfillmentType', 'delivery_mode', 'type'],
      ),
      shippingAddress: _formatAddress(
        _firstValue(
          json,
          const [
            'shipping_address',
            'shippingAddress',
            'delivery_address',
            'address',
          ],
        ),
      ),
      paymentMethod: _formatPayment(
        _firstValue(
          json,
          const ['payment_method', 'paymentMethod', 'payment_method_name'],
        ),
      ),
      estimatedDelivery: _formatDate(
        _firstValue(
          json,
          const ['estimated_delivery', 'estimatedDelivery', 'eta'],
        ),
      ),
      actualDelivery: _formatDate(
        _firstValue(
          json,
          const [
            'actual_delivery',
            'actualDelivery',
            'delivered_at',
            'deliveredAt',
          ],
        ),
      ),
      items: items,
    );
  }
}

class RecentOrderItem {
  const RecentOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;

  factory RecentOrderItem.fromJson(Map<String, dynamic> json) {
    return RecentOrderItem(
      name: _firstString(
        json,
        const ['product_name', 'productName', 'name', 'title'],
        fallback: _formatNestedName(json['product']),
      ),
      quantity: _firstInt(json, const ['quantity', 'qty', 'count'], fallback: 1),
      price: _firstDouble(
        json,
        const ['price', 'unit_price', 'unitPrice', 'total_price', 'totalPrice'],
      ),
    );
  }
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is String && value.trim().isEmpty) continue;
    return value;
  }
  return null;
}

String _firstString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  final value = _firstValue(json, keys);
  if (value == null) return fallback;
  return value.toString().trim().isEmpty ? fallback : value.toString().trim();
}

double _firstDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toDouble();
  final text = value?.toString() ?? '';
  final normalized = text.replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(normalized) ?? 0;
}

int _firstInt(
  Map<String, dynamic> json,
  List<String> keys, {
  int fallback = 0,
}) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<Map<String, dynamic>> _readList(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final value = _firstValue(json, keys);
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map(
        (item) => item.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      )
      .toList(growable: false);
}

String _formatDate(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    final milliseconds = value > 100000000000
        ? value.toInt()
        : value.toInt() * 1000;
    return _formatDateTime(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return '';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return _formatDateTime(parsed.toLocal());
}

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  if (hour == '00' && minute == '00') {
    return '${value.year}-$month-$day';
  }
  return '${value.year}-$month-$day $hour:$minute';
}

String _formatAddress(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is Map) {
    final data = value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    final street =
        data['street'] ??
        data['line1'] ??
        data['address_line1'] ??
        data['address'];
    final province = data['province'] ?? data['state'];
    final postalCode = data['postal_code'] ?? data['postalCode'] ?? data['zip'];
    final parts = [
      data['receiver_name'] ?? data['receiverName'],
      street,
      data['city'],
      province,
      postalCode,
      data['country'],
    ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .map((part) => part.toString().trim())
        .toList();
    return parts.join(', ');
  }
  return value.toString();
}

String _formatPayment(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is Map) {
    final data = value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    final label = data['display_label'] ?? data['displayLabel'] ?? data['label'];
    final brand = data['card_brand'] ?? data['brand'] ?? data['type'];
    final last4 = data['card_last4'] ?? data['last4'] ?? data['last_four'];
    if (label != null && label.toString().trim().isNotEmpty) {
      return label.toString().trim();
    }
    if (brand != null && last4 != null) {
      return '${_humanize(brand.toString())} ending in $last4';
    }
  }
  return value.toString();
}

String _formatNestedName(dynamic value) {
  if (value is Map) {
    final data = value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
    return _firstString(data, const ['name', 'title'], fallback: 'Item');
  }
  return 'Item';
}

String _humanize(String value) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) return '';

  return cleaned
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        final lower = word.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

int _statusRank(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('cancel') || normalized.contains('refund')) return -1;
  if (normalized.contains('deliver') ||
      normalized.contains('complete') ||
      normalized.contains('finish')) {
    return 3;
  }
  if (normalized.contains('ship') ||
      normalized.contains('way') ||
      normalized.contains('ready') ||
      normalized.contains('pickup')) {
    return 2;
  }
  if (normalized.contains('prepar') ||
      normalized.contains('process') ||
      normalized.contains('confirm') ||
      normalized.contains('accept') ||
      normalized.contains('paid')) {
    return 1;
  }
  return 0;
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('cancel') || normalized.contains('refund')) {
    return Colors.red.shade700;
  }
  if (normalized.contains('deliver') ||
      normalized.contains('complete') ||
      normalized.contains('finish')) {
    return Colors.green.shade700;
  }
  if (normalized.contains('ship') ||
      normalized.contains('way') ||
      normalized.contains('ready') ||
      normalized.contains('pickup')) {
    return Colors.blue.shade700;
  }
  if (normalized.contains('prepar') ||
      normalized.contains('process') ||
      normalized.contains('confirm') ||
      normalized.contains('accept') ||
      normalized.contains('paid')) {
    return Colors.deepOrange.shade700;
  }
  return Colors.orange.shade800;
}
