import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import '../RegisterPage/phone_login_page.dart';
import 'order_review_page.dart';

class RecentOrdersPage extends StatefulWidget {
  const RecentOrdersPage({super.key});

  @override
  State<RecentOrdersPage> createState() => _RecentOrdersPageState();
}

class _RecentOrdersPageState extends State<RecentOrdersPage> {
  Future<List<RecentOrder>>? _ordersFuture;
  bool? _lastLoginState;
  String? _cancellingOrderId;

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
    final result = await showLoginDialog(
      context,
      reason: LoginPromptReason.recentOrders,
    );
    if (!mounted) return;
    if (result == true) {
      await _reloadOrders();
    }
  }

  Future<void> _confirmCancelOrder(RecentOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text('This will mark ${order.displayId} as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancellingOrderId = order.id);
    final serviceProvider = context.read<ServiceProvider>();
    final cancelled = await serviceProvider.cancelOrder(order.id);
    if (!mounted) return;

    if (cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _reloadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serviceProvider.lastRecentOrdersError ??
                'Order could not be cancelled.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }

    if (mounted) {
      setState(() => _cancellingOrderId = null);
    }
  }

  Future<void> _openReviewPage(RecentOrder order) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => OrderReviewPage(order: order),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      await _reloadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<ServiceProvider>().isLoggedIn;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Recent Orders'),
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
        final providerError = context
            .read<ServiceProvider>()
            .lastRecentOrdersError;
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                isCancelling: _cancellingOrderId == order.id,
                onCancel: order.canCancel
                    ? () => _confirmCancelOrder(order)
                    : null,
                onReview: order.canReview ? () => _openReviewPage(order) : null,
              );
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
  const _OrderCard({
    required this.order,
    this.onCancel,
    this.onReview,
    this.isCancelling = false,
  });

  final RecentOrder order;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dividerColor = primary.withValues(alpha: 0.22);
    final color = _statusColor(context, order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.055),
              border: Border(bottom: BorderSide(color: dividerColor, width: 2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.dateLabel,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(label: order.status, color: color),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusTimeline(order: order),
                const SizedBox(height: 14),
                Divider(height: 1, color: dividerColor),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.shopping_bag_outlined,
                  label:
                      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.payments_outlined,
                  label: _formatMoney(order.currency, order.totalAmount),
                ),
                if (order.hasRefund) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.replay_outlined,
                    label:
                        '${order.refundLabel}: ${_formatMoney(order.currency, order.refundedAmount)}',
                    color: _refundColor(order),
                  ),
                ],
                if (order.paymentStatusLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.credit_card_outlined,
                    label: 'Payment: ${order.paymentStatusLabel}',
                  ),
                ],
                if (order.fulfillmentLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.storefront_outlined,
                    label: order.fulfillmentLabel,
                  ),
                ],
                if (order.rewardDiscount > 0) ...[
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.local_offer_outlined,
                    label:
                        'Reward: ${_formatMoney(order.currency, -order.rewardDiscount)}',
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (onCancel != null)
                        TextButton.icon(
                          onPressed: isCancelling ? null : onCancel,
                          icon: isCancelling
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red.shade700,
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(
                            isCancelling ? 'Cancelling...' : 'Cancel',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      if (onReview != null)
                        TextButton.icon(
                          onPressed: onReview,
                          icon: Icon(
                            order.isReviewed
                                ? Icons.rate_review_outlined
                                : Icons.star_rate_outlined,
                            size: 18,
                          ),
                          label: Text(
                            order.isReviewed ? 'Edit Review' : 'Review',
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => _showOrderDetails(context, order),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('View Details'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, RecentOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dividerColor = primary.withValues(alpha: 0.22);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
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
                    color: primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    bottom: BorderSide(color: dividerColor, width: 2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        order.displayId,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(
                      label: order.status,
                      color: _statusColor(context, order.status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Status', value: order.status),
              _DetailRow(label: 'Payment', value: order.paymentStatusLabel),
              if (order.hasRefund)
                _DetailRow(
                  label: order.refundLabel,
                  value: _formatMoney(order.currency, order.refundedAmount),
                  valueColor: _refundColor(order),
                ),
              _DetailRow(label: 'Date', value: order.dateLabel),
              _DetailRow(label: 'Fulfillment', value: order.fulfillmentLabel),
              _DetailRow(label: 'Payment Method', value: order.paymentMethod),
              if (order.rewardDiscount > 0)
                _DetailRow(
                  label: 'Reward Discount',
                  value:
                      '${_formatMoney(order.currency, -order.rewardDiscount)}${order.rewardTitle.isEmpty ? '' : ' (${order.rewardTitle})'}',
                ),
              _DetailRow(
                label: 'Estimated Delivery',
                value: order.estimatedDelivery,
              ),
              _DetailRow(label: 'Delivered', value: order.actualDelivery),
              _DetailRow(label: 'Address', value: order.shippingAddress),
              _DetailRow(label: 'Order Note', value: order.orderNote),
              if (order.isReviewed)
                _DetailRow(
                  label: 'Review',
                  value: order.reviewComment.isEmpty
                      ? 'Product ratings submitted'
                      : order.reviewComment,
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Items',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 6),
                    if (order.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          'No item details available.',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.60),
                          ),
                        ),
                      )
                    else
                      ...order.items.map(
                        (item) => _OrderItemLine(
                          item: item,
                          currency: order.currency,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OrderPricingSummary(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPricingSummary extends StatelessWidget {
  const _OrderPricingSummary({required this.order});

  final RecentOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dividerColor = primary.withValues(alpha: 0.22);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Order Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 6),
          _PriceSummaryRow(
            label: 'Subtotal',
            value: _formatMoney(order.currency, order.subtotal),
          ),
          if (order.shouldShowDeliveryFees) ...[
            _PriceSummaryRow(
              label: 'Delivery Fee',
              value: _formatMoney(order.currency, order.deliveryFee),
            ),
            _PriceSummaryRow(
              label: 'Delivery Service Fee',
              value: _formatMoney(order.currency, order.deliveryServiceFee),
            ),
          ],
          _PriceSummaryRow(
            label: 'Taxes',
            value: _formatMoney(order.currency, order.taxes),
          ),
          _PriceSummaryRow(
            label: 'Tip',
            value: _formatMoney(order.currency, order.tipAmount),
          ),
          if (order.rewardDiscount > 0)
            _PriceSummaryRow(
              label: order.rewardTitle.isEmpty
                  ? 'Reward Discount'
                  : 'Reward Discount (${order.rewardTitle})',
              value: _formatMoney(order.currency, -order.rewardDiscount),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: dividerColor, thickness: 1.2),
          ),
          _PriceSummaryRow(
            label: 'Total',
            value: _formatMoney(order.currency, order.totalAmount),
            isTotal: true,
          ),
          if (order.hasRefund) ...[
            const SizedBox(height: 6),
            _PriceSummaryRow(
              label: order.refundLabel,
              value: _formatMoney(order.currency, order.refundedAmount),
              valueColor: _refundColor(order),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceSummaryRow extends StatelessWidget {
  const _PriceSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal
                    ? Colors.black
                    : Colors.black.withValues(alpha: 0.66),
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemLine extends StatelessWidget {
  const _OrderItemLine({required this.item, required this.currency});

  final RecentOrderItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final price = item.price > 0 ? _formatMoney(currency, item.price) : '';
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${item.quantity}x ${item.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (item.isRewardItem)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Reward',
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (price.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          if (item.optionsLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.optionsLabel,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.62),
                fontSize: 12,
              ),
            ),
          ],
          if (item.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Note: ${item.specialInstructions}',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.62),
                fontSize: 12,
              ),
            ),
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
    final rank = _statusRank(order.timelineStatus);
    if (rank < 0) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This order is ${order.timelineStatus.toLowerCase()}.',
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
    final primary = Theme.of(context).colorScheme.primary;
    final color = isComplete ? primary : primary.withValues(alpha: 0.34);
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
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
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
  const _InfoLine({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? primary.withValues(alpha: 0.82)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? Colors.black.withValues(alpha: 0.78),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: primary.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black.withValues(alpha: 0.84),
                fontWeight: FontWeight.w700,
              ),
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 92, 24, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: primary),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.68)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ],
            ),
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
    required this.timelineStatus,
    required this.dateLabel,
    required this.currency,
    required this.totalAmount,
    required this.refundedAmount,
    required this.refundableAmount,
    required this.refunds,
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryServiceFee,
    required this.taxes,
    required this.tipAmount,
    required this.totalBeforeRewards,
    required this.itemCount,
    required this.fulfillmentType,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.rewardDiscount,
    required this.rewardTitle,
    required this.estimatedDelivery,
    required this.actualDelivery,
    required this.orderNote,
    required this.items,
    required this.canReview,
    required this.isReviewed,
    required this.reviewComment,
  });

  final String id;
  final String status;
  final String timelineStatus;
  final String dateLabel;
  final String currency;
  final double totalAmount;
  final double refundedAmount;
  final double refundableAmount;
  final List<Map<String, dynamic>> refunds;
  final double subtotal;
  final double deliveryFee;
  final double deliveryServiceFee;
  final double taxes;
  final double tipAmount;
  final double totalBeforeRewards;
  final int itemCount;
  final String fulfillmentType;
  final String shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final double rewardDiscount;
  final String rewardTitle;
  final String estimatedDelivery;
  final String actualDelivery;
  final String orderNote;
  final List<RecentOrderItem> items;
  final bool canReview;
  final bool isReviewed;
  final String reviewComment;

  String get displayId => id.isEmpty ? 'Order' : 'Order #$id';

  bool get isDelivery => fulfillmentType.toLowerCase().contains('delivery');

  bool get shouldShowDeliveryFees =>
      isDelivery || deliveryFee > 0 || deliveryServiceFee > 0;

  String get fulfillmentLabel => _humanize(fulfillmentType);

  String get paymentStatusLabel => _humanize(paymentStatus);

  bool get hasRefund => refundedAmount > 0.005;

  bool get isPartiallyRefunded => _isPartiallyRefundedStatus(status);

  bool get isRefunded => _isRefundedStatus(status);

  String get refundLabel =>
      isPartiallyRefunded ? 'Partially Refunded' : 'Refunded';

  bool get canCancel {
    if (id.trim().isEmpty) return false;
    final normalized = status.toLowerCase();
    return normalized == 'created' || normalized == 'paid';
  }

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    final items = _readList(json, const [
      'items',
      'order_items',
      'orderItems',
      'products',
    ]).map(RecentOrderItem.fromJson).toList(growable: false);
    final dateLabel = _formatDate(
      _firstValue(json, const [
        'created_at',
        'createdAt',
        'order_date',
        'orderDate',
        'date',
      ]),
    );
    final paymentValue = _firstValue(json, const ['payment']);
    final paymentMap = paymentValue is Map
        ? paymentValue.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final rawStatus = _firstString(json, const [
      'status',
      'order_status',
      'orderStatus',
      'current_status',
    ], fallback: 'Pending');
    final reviewValue = _firstValue(json, const ['review', 'order_review']);
    final reviewMap = reviewValue is Map
        ? reviewValue.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final fulfillmentValue = _firstValue(json, const [
      'fulfillment_detail',
      'fulfillmentDetail',
    ]);
    final fulfillmentMap = fulfillmentValue is Map
        ? fulfillmentValue.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final rawTimelineStatus = _isPartiallyRefundedStatus(rawStatus)
        ? _timelineStatusFromFulfillment(fulfillmentMap, rawStatus)
        : rawStatus;
    final pricingValue =
        _firstValue(json, const ['pricing']) ?? fulfillmentMap['pricing'];
    final pricingMap = pricingValue is Map
        ? pricingValue.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final rewardValue =
        _firstValue(json, const ['reward', 'reward_redemption']) ??
        fulfillmentMap['reward'];
    final rewardMap = rewardValue is Map
        ? rewardValue.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    final inferredCanReview =
        rawStatus.toLowerCase() == 'completed' ||
        rawStatus.toLowerCase() == 'delivered';
    final itemSubtotal = items.fold<double>(0, (sum, item) => sum + item.price);
    final pricingSubtotal = _firstDouble(pricingMap, const ['subtotal']);
    final subtotal = pricingSubtotal > 0 ? pricingSubtotal : itemSubtotal;
    final deliveryFee = _firstDouble(pricingMap, const [
      'delivery_fee',
      'deliveryFee',
    ]);
    final deliveryServiceFee = _firstDouble(pricingMap, const [
      'delivery_service_fee',
      'deliveryServiceFee',
    ]);
    final taxes = _firstDouble(pricingMap, const ['taxes', 'tax']);
    final tipAmount = _firstDouble(pricingMap, const [
      'tip_amount',
      'tipAmount',
      'tip',
    ]);
    final rewardDiscount = _firstDouble(pricingMap, const [
      'reward_discount',
      'rewardDiscount',
    ]);
    final pricingTotalBeforeRewards = _firstDouble(pricingMap, const [
      'total_before_rewards',
      'totalBeforeRewards',
    ]);
    final pricingTotal = _firstDouble(pricingMap, const ['total']);
    final rawTotalAmount = _firstDouble(json, const [
      'total_amount',
      'totalAmount',
      'grand_total',
      'total',
      'amount',
    ]);
    final calculatedTotalBeforeRewards =
        subtotal + deliveryFee + deliveryServiceFee + taxes + tipAmount;
    final totalBeforeRewards = pricingTotalBeforeRewards > 0
        ? pricingTotalBeforeRewards
        : calculatedTotalBeforeRewards;
    final totalAmount = rawTotalAmount > 0
        ? rawTotalAmount
        : pricingTotal > 0
        ? pricingTotal
        : (totalBeforeRewards - rewardDiscount)
              .clamp(0, double.infinity)
              .toDouble();
    final topLevelRefundedAmount = _firstDouble(json, const [
      'refunded_amount',
      'refundedAmount',
    ]);
    final paymentRefundedAmount = _firstDouble(paymentMap, const [
      'refunded_amount',
      'refundedAmount',
    ]);
    final refundedAmount = topLevelRefundedAmount > 0
        ? topLevelRefundedAmount
        : paymentRefundedAmount;
    final topLevelRefundableAmount = _firstDouble(json, const [
      'refundable_amount',
      'refundableAmount',
    ]);
    final paymentRefundableAmount = _firstDouble(paymentMap, const [
      'refundable_amount',
      'refundableAmount',
    ]);
    final refundableAmount = topLevelRefundableAmount > 0
        ? topLevelRefundableAmount
        : paymentRefundableAmount;
    final topLevelRefunds = _readList(json, const ['refunds']);
    final paymentRefunds = _readList(paymentMap, const ['refunds']);

    return RecentOrder(
      id: _firstString(json, const [
        'order_id',
        'orderId',
        'order_no',
        'orderNumber',
        'id',
      ]),
      status: _humanize(rawStatus),
      timelineStatus: _humanize(rawTimelineStatus),
      dateLabel: dateLabel.isEmpty ? 'Date unavailable' : dateLabel,
      currency: _firstString(json, const ['currency'], fallback: 'CAD'),
      totalAmount: totalAmount,
      refundedAmount: refundedAmount,
      refundableAmount: refundableAmount,
      refunds: topLevelRefunds.isNotEmpty ? topLevelRefunds : paymentRefunds,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      deliveryServiceFee: deliveryServiceFee,
      taxes: taxes,
      tipAmount: tipAmount,
      totalBeforeRewards: totalBeforeRewards,
      itemCount: _firstInt(json, const [
        'item_count',
        'itemCount',
        'total_items',
        'totalItems',
      ], fallback: items.fold<int>(0, (sum, item) => sum + item.quantity)),
      fulfillmentType: _firstString(json, const [
        'fulfillment_type',
        'fulfillmentType',
        'delivery_mode',
        'type',
      ]),
      shippingAddress: _formatAddress(
        _firstValue(json, const [
          'shipping_address',
          'shippingAddress',
          'delivery_address',
          'address',
        ]),
      ),
      paymentMethod: _formatPayment(
        _firstValue(json, const [
          'payment_method',
          'paymentMethod',
          'payment_method_name',
        ]),
      ),
      paymentStatus: _firstString(
        json,
        const ['payment_status', 'paymentStatus'],
        fallback: _firstString(paymentMap, const [
          'payment_status',
          'paymentStatus',
          'status',
        ]),
      ),
      rewardDiscount: rewardDiscount,
      rewardTitle: _firstString(rewardMap, const ['title', 'name']),
      estimatedDelivery: _formatDate(
        _firstValue(json, const [
          'estimated_delivery',
          'estimatedDelivery',
          'eta',
        ]),
      ),
      actualDelivery: _formatDate(
        _firstValue(json, const [
          'actual_delivery',
          'actualDelivery',
          'delivered_at',
          'deliveredAt',
        ]),
      ),
      orderNote: _firstString(
        json,
        const ['order_note', 'orderNote'],
        fallback: _firstString(fulfillmentMap, const [
          'order_note',
          'orderNote',
        ]),
      ),
      items: items,
      canReview: _firstBool(json, const [
        'can_review',
        'canReview',
      ], fallback: inferredCanReview),
      isReviewed: _firstBool(json, const [
        'is_reviewed',
        'isReviewed',
        'reviewed',
      ], fallback: reviewMap.isNotEmpty),
      reviewComment: _firstString(reviewMap, const [
        'comment',
        'message',
        'review_comment',
        'reviewComment',
      ]),
    );
  }
}

class RecentOrderItem {
  const RecentOrderItem({
    required this.orderItemId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.itemSource = 'normal',
    this.reviewRating = 0,
    this.options = const [],
    this.specialInstructions = '',
  });

  final String orderItemId;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String itemSource;
  final int reviewRating;
  final List<RecentOrderItemOption> options;
  final String specialInstructions;

  bool get isRewardItem => itemSource.toLowerCase() == 'reward';

  String get optionsLabel {
    if (options.isEmpty) return '';

    final grouped = <String, List<String>>{};
    for (final option in options) {
      final optionName = option.name.trim();
      if (optionName.isEmpty) continue;

      final groupName = option.groupName.trim();
      grouped.putIfAbsent(groupName, () => <String>[]).add(optionName);
    }

    return grouped.entries
        .map((entry) {
          final names = entry.value.join(', ');
          return entry.key.isEmpty ? names : '${entry.key}: $names';
        })
        .where((text) => text.trim().isNotEmpty)
        .join(' · ');
  }

  factory RecentOrderItem.fromJson(Map<String, dynamic> json) {
    return RecentOrderItem(
      orderItemId: _firstString(json, const [
        'order_item_id',
        'orderItemId',
        'id',
      ]),
      productId: _firstString(json, const ['product_id', 'productId']),
      name: _firstString(json, const [
        'product_name',
        'productName',
        'name',
        'title',
      ], fallback: _formatNestedName(json['product'])),
      quantity: _firstInt(json, const [
        'quantity',
        'qty',
        'count',
      ], fallback: 1),
      price: _firstDouble(json, const [
        'price',
        'unit_price',
        'unitPrice',
        'total_price',
        'totalPrice',
      ]),
      itemSource: _firstString(json, const [
        'item_source',
        'itemSource',
      ], fallback: 'normal'),
      reviewRating: _firstInt(json, const [
        'review_rating',
        'reviewRating',
        'rating',
      ]),
      options: _readList(json, const [
        'selected_options',
        'selectedOptions',
        'order_item_options',
        'orderItemOptions',
        'options',
      ]).map(RecentOrderItemOption.fromJson).toList(growable: false),
      specialInstructions: _firstString(json, const [
        'special_instructions',
        'specialInstructions',
      ]),
    );
  }
}

class RecentOrderItemOption {
  const RecentOrderItemOption({required this.name, this.groupName = ''});

  final String name;
  final String groupName;

  factory RecentOrderItemOption.fromJson(Map<String, dynamic> json) {
    return RecentOrderItemOption(
      name: _firstString(json, const [
        'option_name',
        'optionName',
        'name',
        'title',
        'product_name',
        'productName',
      ]),
      groupName: _firstString(json, const [
        'group_name',
        'groupName',
        'option_group_name',
        'optionGroupName',
      ]),
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

bool _firstBool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  final value = _firstValue(json, keys);
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  if (text == 'true' || text == 'yes' || text == '1') return true;
  if (text == 'false' || text == 'no' || text == '0') return false;
  return fallback;
}

String _formatMoney(String currency, double amount) {
  final code = currency.trim().isEmpty ? 'CAD' : currency.trim().toUpperCase();
  final sign = amount < 0 ? '-' : '';
  return '$sign$code \$${amount.abs().toStringAsFixed(2)}';
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

String _timelineStatusFromFulfillment(
  Map<String, dynamic> fulfillmentMap,
  String fallback,
) {
  final events = _readList(fulfillmentMap, const [
    'merchant_events',
    'merchantEvents',
    'status_history',
    'statusHistory',
  ]);
  for (final event in events.reversed) {
    final status = _firstString(event, const [
      'status',
      'order_status',
      'orderStatus',
    ]);
    final normalizedStatus = status.toLowerCase();
    if (_isPartiallyRefundedStatus(status) || _isRefundedStatus(status)) {
      final previousStatus = _firstString(event, const [
        'previous_status',
        'previousStatus',
      ]);
      if (_isFulfillmentProgressStatus(previousStatus)) {
        return previousStatus;
      }
      continue;
    }
    if (_isFulfillmentProgressStatus(normalizedStatus)) return status;
  }

  return fallback;
}

bool _isFulfillmentProgressStatus(String status) {
  final normalized = status.toLowerCase();
  if (normalized.isEmpty) return false;
  if (normalized.contains('cancel') ||
      _isPartiallyRefundedStatus(normalized) ||
      _isRefundedStatus(normalized)) {
    return false;
  }
  return normalized == 'created' ||
      normalized == 'paid' ||
      normalized == 'accepted' ||
      normalized == 'preparing' ||
      normalized == 'ready' ||
      normalized == 'on_the_way' ||
      normalized == 'delivered' ||
      normalized == 'completed';
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
    final parts =
        [
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
    final label =
        data['display_label'] ?? data['displayLabel'] ?? data['label'];
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
  if (normalized.contains('cancel') || _isRefundedStatus(normalized)) return -1;
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

bool _isPartiallyRefundedStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('partial') && normalized.contains('refund');
}

bool _isRefundedStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('refund') &&
      !_isPartiallyRefundedStatus(normalized);
}

Color _refundColor(RecentOrder order) {
  if (order.isPartiallyRefunded) return Colors.deepOrange.shade700;
  return Colors.red.shade700;
}

Color _statusColor(BuildContext context, String status) {
  final normalized = status.toLowerCase();
  if (_isPartiallyRefundedStatus(normalized)) {
    return Colors.deepOrange.shade700;
  }
  if (normalized.contains('cancel') || _isRefundedStatus(normalized)) {
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
    return Theme.of(context).colorScheme.primary;
  }
  return Theme.of(context).colorScheme.primary;
}
