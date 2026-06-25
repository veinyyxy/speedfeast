import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import '../RegisterPage/phone_login_page.dart';

class RewardsActivityPage extends StatefulWidget {
  const RewardsActivityPage({super.key});

  @override
  State<RewardsActivityPage> createState() => _RewardsActivityPageState();
}

class _RewardsActivityPageState extends State<RewardsActivityPage> {
  Future<_RewardsActivityData>? _activityFuture;
  bool? _lastLoginState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLoggedIn = context.watch<ServiceProvider>().isLoggedIn;
    if (_lastLoginState == isLoggedIn) return;

    _lastLoginState = isLoggedIn;
    _activityFuture = isLoggedIn ? _fetchActivity() : null;
  }

  Future<_RewardsActivityData> _fetchActivity() async {
    final serviceProvider = context.read<ServiceProvider>();
    final response = await serviceProvider.fetchRewardsTransactions();
    final redemptionsResponse = await serviceProvider.fetchRewardRedemptions();
    return _RewardsActivityData.fromJson(
      response ?? <String, dynamic>{},
      redemptionsResponse ?? <String, dynamic>{},
    );
  }

  Future<void> _reloadActivity() async {
    final future = _fetchActivity();
    setState(() {
      _activityFuture = future;
    });
    await future;
  }

  Future<void> _showLoginDialog() async {
    final result = await showLoginDialog(
      context,
      reason: LoginPromptReason.account,
    );
    if (!mounted) return;
    if (result == true) {
      await _reloadActivity();
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
          'POINTS ACTIVITY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (isLoggedIn)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _reloadActivity,
            ),
        ],
      ),
      body: isLoggedIn ? _buildActivityBody() : _buildSignedOutState(),
    );
  }

  Widget _buildActivityBody() {
    return FutureBuilder<_RewardsActivityData>(
      future: _activityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ScrollableStateMessage(
            icon: Icons.error_outline,
            title: 'Rewards could not be loaded',
            message: snapshot.error.toString(),
            buttonLabel: 'Try Again',
            onPressed: _reloadActivity,
          );
        }

        final data = snapshot.data ?? _RewardsActivityData.empty();
        final providerError = context.read<ServiceProvider>().lastRewardsError;

        if (data.transactions.isEmpty && providerError != null) {
          return _ScrollableStateMessage(
            icon: Icons.wifi_off_outlined,
            title: 'Rewards could not be loaded',
            message: providerError,
            buttonLabel: 'Try Again',
            onPressed: _reloadActivity,
          );
        }

        return RefreshIndicator(
          onRefresh: _reloadActivity,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _RewardsSummaryCard(account: data.account),
              const SizedBox(height: 16),
              Text(
                'My Rewards',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (data.redemptions.isEmpty)
                const _EmptyRewardsCard()
              else
                SizedBox(
                  height: 126,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.redemptions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _RewardRedemptionCard(
                        redemption: data.redemptions[index],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (data.transactions.isEmpty)
                _EmptyActivityCard(onRefresh: _reloadActivity)
              else
                ...data.transactions.map(
                  (transaction) =>
                      _RewardsTransactionCard(transaction: transaction),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignedOutState() {
    return _ScrollableStateMessage(
      icon: Icons.lock_outline,
      title: 'Sign in to view points',
      message: 'Rewards activity is linked to your SpeedFeast account.',
      buttonLabel: 'Sign In',
      onPressed: _showLoginDialog,
    );
  }
}

class _RewardRedemptionCard extends StatelessWidget {
  const _RewardRedemptionCard({required this.redemption});

  final _RewardRedemption redemption;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 210,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: primaryColor.withAlpha(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_outlined, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      redemption.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                redemption.valueLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                redemption.expiryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${redemption.pointsCost} pts redeemed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRewardsCard extends StatelessWidget {
  const _EmptyRewardsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Redeemed vouchers will appear here.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsSummaryCard extends StatelessWidget {
  const _RewardsSummaryCard({required this.account});

  final _RewardsAccount account;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final nextTarget = account.nextRewardPoints > 0
        ? account.nextRewardPoints
        : 300;
    final progress = nextTarget <= 0
        ? 0.0
        : (account.availablePoints / nextTarget).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: primaryColor.withAlpha(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  account.availablePoints.toString(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 0.95,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'pts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next reward at $nextTarget pts',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'Lifetime earned',
                    value: account.lifetimeEarnedPoints.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Redeemed',
                    value: account.lifetimeRedeemedPoints.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Pending',
                    value: account.pendingPoints.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RewardsTransactionCard extends StatelessWidget {
  const _RewardsTransactionCard({required this.transaction});

  final _RewardsTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final color = transaction.points >= 0
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(transaction.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.subtitle,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (transaction.orderLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.orderLabel,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              transaction.pointsLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.stars_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            const Text(
              'No points activity yet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Completed orders will appear here after points are awarded.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
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
    return RefreshIndicator(
      onRefresh: () async => onPressed(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}

class _RewardsActivityData {
  final _RewardsAccount account;
  final List<_RewardRedemption> redemptions;
  final List<_RewardsTransaction> transactions;

  const _RewardsActivityData({
    required this.account,
    required this.redemptions,
    required this.transactions,
  });

  factory _RewardsActivityData.empty() {
    return _RewardsActivityData(
      account: _RewardsAccount.empty(),
      redemptions: const [],
      transactions: const [],
    );
  }

  factory _RewardsActivityData.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> redemptionsJson,
  ) {
    final accountJson = json['account'] is Map
        ? Map<String, dynamic>.from(json['account'] as Map)
        : <String, dynamic>{};
    final transactionsJson = json['transactions'] is List
        ? json['transactions'] as List
        : const [];
    final redemptionList = redemptionsJson['redemptions'] is List
        ? redemptionsJson['redemptions'] as List
        : const [];

    return _RewardsActivityData(
      account: _RewardsAccount.fromJson(accountJson),
      redemptions: redemptionList
          .whereType<Map>()
          .map(
            (item) =>
                _RewardRedemption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      transactions: transactionsJson
          .whereType<Map>()
          .map(
            (item) =>
                _RewardsTransaction.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}

class _RewardRedemption {
  final String id;
  final String title;
  final int pointsCost;
  final double discountAmount;
  final String currency;
  final String status;
  final String expiresAt;
  final String rewardType;
  final String productName;

  const _RewardRedemption({
    required this.id,
    required this.title,
    required this.pointsCost,
    required this.discountAmount,
    required this.currency,
    required this.status,
    required this.expiresAt,
    required this.rewardType,
    required this.productName,
  });

  factory _RewardRedemption.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] is Map
        ? Map<String, dynamic>.from(json['reward'] as Map)
        : <String, dynamic>{};
    final pointsCost = _readInt(json, const ['points_cost', 'pointsCost']);
    final discountAmount = _readDouble(json, const [
      'discount_amount',
      'discountAmount',
    ]);
    final rewardTitle = _readString(reward, const ['title', 'name']);
    final rewardType =
        _readString(json, const ['reward_type', 'rewardType']).isNotEmpty
        ? _readString(json, const ['reward_type', 'rewardType'])
        : _readString(reward, const ['reward_type', 'rewardType']).isNotEmpty
        ? _readString(reward, const ['reward_type', 'rewardType'])
        : 'discount';
    final productName =
        _readString(json, const ['product_name', 'productName']).isNotEmpty
        ? _readString(json, const ['product_name', 'productName'])
        : _readString(reward, const ['product_name', 'productName']);

    return _RewardRedemption(
      id: _readString(json, const ['redemption_id', 'redemptionId', 'id']),
      title: rewardTitle.isNotEmpty
          ? rewardTitle
          : _readString(json, const ['title', 'name']),
      pointsCost: pointsCost,
      discountAmount: rewardType == 'product'
          ? 0
          : discountAmount <= 0
          ? pointsCost / 100
          : discountAmount,
      currency: _readString(json, const ['currency']).isEmpty
          ? 'CAD'
          : _readString(json, const ['currency']),
      status: _readString(json, const ['status']),
      expiresAt: _readString(json, const ['expires_at', 'expiresAt']),
      rewardType: rewardType,
      productName: productName,
    );
  }

  bool get isProductReward => rewardType.toLowerCase() == 'product';

  String get valueLabel {
    if (isProductReward) {
      return productName.isEmpty
          ? 'Free product'
          : 'Free product: $productName';
    }
    return discountLabel;
  }

  String get discountLabel {
    return '${currency.toUpperCase()} \$${discountAmount.toStringAsFixed(2)} off';
  }

  String get expiryLabel {
    final date = _formatDate(expiresAt);
    if (date.isEmpty) return _titleCase(status);
    return 'Expires $date';
  }
}

class _RewardsAccount {
  final int availablePoints;
  final int pendingPoints;
  final int lifetimeEarnedPoints;
  final int lifetimeRedeemedPoints;
  final int nextRewardPoints;

  const _RewardsAccount({
    required this.availablePoints,
    required this.pendingPoints,
    required this.lifetimeEarnedPoints,
    required this.lifetimeRedeemedPoints,
    required this.nextRewardPoints,
  });

  factory _RewardsAccount.empty() {
    return const _RewardsAccount(
      availablePoints: 0,
      pendingPoints: 0,
      lifetimeEarnedPoints: 0,
      lifetimeRedeemedPoints: 0,
      nextRewardPoints: 300,
    );
  }

  factory _RewardsAccount.fromJson(Map<String, dynamic> json) {
    return _RewardsAccount(
      availablePoints: _readInt(json, const [
        'available_points',
        'availablePoints',
      ]),
      pendingPoints: _readInt(json, const ['pending_points', 'pendingPoints']),
      lifetimeEarnedPoints: _readInt(json, const [
        'lifetime_earned_points',
        'lifetimeEarnedPoints',
      ]),
      lifetimeRedeemedPoints: _readInt(json, const [
        'lifetime_redeemed_points',
        'lifetimeRedeemedPoints',
      ]),
      nextRewardPoints:
          _readInt(json, const ['next_reward_points', 'nextRewardPoints']) == 0
          ? 300
          : _readInt(json, const ['next_reward_points', 'nextRewardPoints']),
    );
  }
}

class _RewardsTransaction {
  final String id;
  final String orderId;
  final String type;
  final String status;
  final int points;
  final String description;
  final String createdAt;
  final String orderStatus;

  const _RewardsTransaction({
    required this.id,
    required this.orderId,
    required this.type,
    required this.status,
    required this.points,
    required this.description,
    required this.createdAt,
    required this.orderStatus,
  });

  factory _RewardsTransaction.fromJson(Map<String, dynamic> json) {
    return _RewardsTransaction(
      id: _readString(json, const ['transaction_id', 'transactionId', 'id']),
      orderId: _readString(json, const ['order_id', 'orderId']),
      type: _readString(json, const ['transaction_type', 'transactionType']),
      status: _readString(json, const [
        'transaction_status',
        'transactionStatus',
        'status',
      ]),
      points: _readInt(json, const ['points']),
      description: _readString(json, const ['description']),
      createdAt: _readString(json, const ['created_at', 'createdAt']),
      orderStatus: _readString(json, const ['order_status', 'orderStatus']),
    );
  }

  IconData get icon {
    switch (type) {
      case 'redeem':
        return Icons.redeem_outlined;
      case 'refund':
        return Icons.undo_outlined;
      case 'adjustment':
        return Icons.tune_outlined;
      case 'earn':
      default:
        return Icons.add_circle_outline;
    }
  }

  String get title {
    if (description.trim().isNotEmpty) return description;
    switch (type) {
      case 'redeem':
        return 'Redeemed points';
      case 'refund':
        return 'Points refunded';
      case 'adjustment':
        return 'Points adjusted';
      case 'earn':
      default:
        return 'Earned points';
    }
  }

  String get subtitle {
    final parts = <String>[
      _formatDate(createdAt),
      if (status.isNotEmpty) _titleCase(status),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Rewards activity' : parts.join(' • ');
  }

  String get orderLabel {
    if (orderId.isEmpty) return '';
    final shortOrder = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final statusLabel = orderStatus.isEmpty
        ? ''
        : ' • ${_titleCase(orderStatus)}';
    return 'Order #$shortOrder$statusLabel';
  }

  String get pointsLabel {
    final sign = points > 0 ? '+' : '';
    return '$sign$points pts';
  }
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

String _formatDate(String value) {
  if (value.isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.year}-$month-$day $hour:$minute $suffix';
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return '';
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}
