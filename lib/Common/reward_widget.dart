import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import '../RegisterPage/phone_login_page.dart';

class RewardWidget extends StatefulWidget {
  const RewardWidget({super.key});

  @override
  State<RewardWidget> createState() => _RewardWidgetState();
}

class _RewardWidgetState extends State<RewardWidget> {
  bool _isExpanded = false;
  bool? _lastLoggedIn;
  String? _redeemingRewardId;
  Future<_RewardSummary?>? _summaryFuture;

  Future<_RewardSummary?> _loadSummary(ServiceProvider serviceProvider) async {
    final response = await serviceProvider.fetchRewardsSummary();
    if (response == null) return null;

    final rawSummary = response['summary'] ?? response['data'] ?? response;
    if (rawSummary is Map) {
      return _RewardSummary.fromJson(Map<String, dynamic>.from(rawSummary));
    }
    return null;
  }

  void _refresh(ServiceProvider serviceProvider) {
    setState(() {
      _summaryFuture = serviceProvider.isLoggedIn
          ? _loadSummary(serviceProvider)
          : Future.value(_RewardSummary.empty());
    });
  }

  Future<void> _confirmRedeem(
    ServiceProvider serviceProvider,
    _RewardItem reward,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Redeem reward?'),
        content: Text(
          'Redeem ${reward.pointsCost} pts for ${reward.discountLabel}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _redeemingRewardId = reward.id);
    final result = await serviceProvider.redeemReward(reward.id);
    if (!mounted) return;

    setState(() => _redeemingRewardId = null);
    final message = result != null
        ? '${reward.discountLabel} voucher added to My Rewards.'
        : serviceProvider.lastRewardsError ?? 'Reward could not be redeemed.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result == null ? Colors.red.shade700 : null,
      ),
    );

    if (result != null) {
      _refresh(serviceProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final isLoggedIn = serviceProvider.isLoggedIn;

    if (_lastLoggedIn != isLoggedIn || _summaryFuture == null) {
      _lastLoggedIn = isLoggedIn;
      _summaryFuture = isLoggedIn
          ? _loadSummary(serviceProvider)
          : Future.value(_RewardSummary.empty());
    }

    return FutureBuilder<_RewardSummary?>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting && isLoggedIn;
        final summary = snapshot.data ?? _RewardSummary.empty();
        return _buildCard(
          context,
          serviceProvider: serviceProvider,
          summary: summary,
          isLoggedIn: isLoggedIn,
          isLoading: isLoading,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required ServiceProvider serviceProvider,
    required _RewardSummary summary,
    required bool isLoggedIn,
    required bool isLoading,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final targetPoints = summary.nextRewardPoints > 0
        ? summary.nextRewardPoints
        : 300;
    final progress = targetPoints <= 0
        ? 0.0
        : (summary.availablePoints / targetPoints).clamp(0.0, 1.0);
    final subtitle = isLoggedIn
        ? summary.availablePoints >= targetPoints && summary.rewards.isNotEmpty
              ? 'You have rewards ready to use'
              : 'Unlock more items at $targetPoints pts'
        : 'Sign in to earn points after completed orders';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        color: primaryColor.withAlpha(18),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: isLoading
                              ? CircularProgressIndicator(
                                  strokeWidth: 4,
                                  color: primaryColor,
                                )
                              : CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 7,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryColor,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          summary.availablePoints.toString(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'pts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/long.jpeg',
                    height: 46,
                    width: 78,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              if (serviceProvider.lastRewardsError != null && isLoggedIn) ...[
                const SizedBox(height: 6),
                Text(
                  serviceProvider.lastRewardsError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (!isLoggedIn)
                ElevatedButton(
                  onPressed: () async {
                    final rewardsProvider = serviceProvider;
                    final signedIn = await showLoginDialog(
                      context,
                      reason: LoginPromptReason.account,
                    );
                    if (signedIn == true && mounted) {
                      _refresh(rewardsProvider);
                    }
                  },
                  style: _primaryButtonStyle(primaryColor),
                  child: const Text(
                    'Sign in for Rewards',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else if (!_isExpanded)
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _isExpanded = true;
                          });
                        },
                  style: _primaryButtonStyle(primaryColor),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Explore Rewards',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              if (isLoggedIn && _isExpanded)
                _RewardsSection(
                  rewards: summary.rewards,
                  availablePoints: summary.availablePoints,
                  redeemingRewardId: _redeemingRewardId,
                  onRedeem: (reward) => _confirmRedeem(serviceProvider, reward),
                  onRefresh: () => _refresh(serviceProvider),
                  onHide: () {
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(Color primaryColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _RewardsSection extends StatefulWidget {
  final List<_RewardItem> rewards;
  final int availablePoints;
  final String? redeemingRewardId;
  final ValueChanged<_RewardItem> onRedeem;
  final VoidCallback onRefresh;
  final VoidCallback onHide;

  const _RewardsSection({
    required this.rewards,
    required this.availablePoints,
    required this.redeemingRewardId,
    required this.onRedeem,
    required this.onRefresh,
    required this.onHide,
  });

  @override
  State<_RewardsSection> createState() => _RewardsSectionState();
}

class _RewardsSectionState extends State<_RewardsSection> {
  int? _selectedPoints;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final rewardsByPoints = _groupRewards(widget.rewards);

    if (rewardsByPoints.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const Divider(height: 12),
          const SizedBox(height: 8),
          Text(
            'Rewards are being prepared.',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 10),
          _ActionRow(
            primaryColor: primaryColor,
            onRefresh: widget.onRefresh,
            onHide: widget.onHide,
          ),
        ],
      );
    }

    final pointOptions = rewardsByPoints.keys.toList()..sort();
    final selectedPoints =
        _selectedPoints != null && rewardsByPoints.containsKey(_selectedPoints)
        ? _selectedPoints!
        : pointOptions.first;
    final currentRewards = rewardsByPoints[selectedPoints] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Divider(height: 12),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: pointOptions.map((points) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildPointButton(
                  context,
                  points,
                  isSelected: selectedPoints == points,
                  onTap: () {
                    setState(() {
                      _selectedPoints = points;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$selectedPoints pts Rewards',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: currentRewards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final reward = currentRewards[index];
              return _RewardVoucherCard(
                reward: reward,
                canRedeem:
                    widget.availablePoints >= reward.pointsCost &&
                    reward.id.isNotEmpty &&
                    widget.redeemingRewardId == null,
                isRedeeming: widget.redeemingRewardId == reward.id,
                onRedeem: () => widget.onRedeem(reward),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _ActionRow(
          primaryColor: primaryColor,
          onRefresh: widget.onRefresh,
          onHide: widget.onHide,
        ),
      ],
    );
  }

  Map<int, List<_RewardItem>> _groupRewards(List<_RewardItem> rewards) {
    final grouped = <int, List<_RewardItem>>{};
    for (final reward in rewards) {
      if (reward.pointsCost <= 0) continue;
      grouped.putIfAbsent(reward.pointsCost, () => []).add(reward);
    }
    return grouped;
  }

  Widget _buildPointButton(
    BuildContext context,
    int points, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Text(
          points.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _RewardVoucherCard extends StatelessWidget {
  const _RewardVoucherCard({
    required this.reward,
    required this.canRedeem,
    required this.isRedeeming,
    required this.onRedeem,
  });

  final _RewardItem reward;
  final bool canRedeem;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 170,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.local_offer_outlined, color: primaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                reward.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                reward.discountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              if (reward.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  reward.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: FilledButton(
                  onPressed: canRedeem ? onRedeem : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isRedeeming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          canRedeem
                              ? 'Redeem'
                              : 'Need ${reward.pointsCost} pts',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onRefresh;
  final VoidCallback onHide;

  const _ActionRow({
    required this.primaryColor,
    required this.onRefresh,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: onRefresh,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(Icons.refresh, color: primaryColor, size: 18),
          label: Text('Refresh', style: TextStyle(color: primaryColor)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onHide,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.grey),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hide', style: TextStyle(color: primaryColor)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_up, color: primaryColor, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardSummary {
  final int availablePoints;
  final int pendingPoints;
  final int lifetimeEarnedPoints;
  final int nextRewardPoints;
  final List<_RewardItem> rewards;

  const _RewardSummary({
    required this.availablePoints,
    required this.pendingPoints,
    required this.lifetimeEarnedPoints,
    required this.nextRewardPoints,
    required this.rewards,
  });

  factory _RewardSummary.empty() {
    return const _RewardSummary(
      availablePoints: 0,
      pendingPoints: 0,
      lifetimeEarnedPoints: 0,
      nextRewardPoints: 300,
      rewards: [],
    );
  }

  factory _RewardSummary.fromJson(Map<String, dynamic> json) {
    final account = json['account'] is Map
        ? Map<String, dynamic>.from(json['account'] as Map)
        : json;
    final rewards = _readList(json, const [
      'rewards',
      'reward_items',
      'rewardItems',
      'items',
    ]).map(_RewardItem.fromJson).toList(growable: false);
    final availablePoints = _readInt(account, const [
      'available_points',
      'availablePoints',
      'points',
    ]);
    final nextRewardPoints =
        _readInt(json, const ['next_reward_points', 'nextRewardPoints']) ??
        _nextRewardTarget(availablePoints ?? 0, rewards);

    return _RewardSummary(
      availablePoints: availablePoints ?? 0,
      pendingPoints:
          _readInt(account, const ['pending_points', 'pendingPoints']) ?? 0,
      lifetimeEarnedPoints:
          _readInt(account, const [
            'lifetime_earned_points',
            'lifetimeEarnedPoints',
          ]) ??
          0,
      nextRewardPoints: nextRewardPoints,
      rewards: rewards,
    );
  }

  static int _nextRewardTarget(int points, List<_RewardItem> rewards) {
    final costs =
        rewards
            .map((reward) => reward.pointsCost)
            .where((cost) => cost > points)
            .toList()
          ..sort();
    if (costs.isNotEmpty) return costs.first;

    final allCosts =
        rewards
            .map((reward) => reward.pointsCost)
            .where((cost) => cost > 0)
            .toList()
          ..sort();
    return allCosts.isNotEmpty ? allCosts.last : 300;
  }
}

class _RewardItem {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final double discountAmount;
  final String currency;

  const _RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.discountAmount,
    required this.currency,
  });

  factory _RewardItem.fromJson(Map<String, dynamic> json) {
    final pointsCost =
        _readInt(json, const ['points_cost', 'pointsCost', 'cost', 'points']) ??
        0;
    return _RewardItem(
      id: _readString(json, const ['reward_id', 'rewardId', 'id']) ?? '',
      title:
          _readString(json, const ['title', 'name', 'reward_name']) ??
          'Reward Item',
      description:
          _readString(json, const ['description', 'reward_type', 'type']) ??
          'Reward',
      pointsCost: pointsCost,
      discountAmount:
          _readDouble(json, const ['discount_amount', 'discountAmount']) ??
          pointsCost / 100,
      currency: _readString(json, const ['currency']) ?? 'CAD',
    );
  }

  String get discountLabel {
    final amount = discountAmount <= 0 ? pointsCost / 100 : discountAmount;
    return '${currency.toUpperCase()} \$${amount.toStringAsFixed(2)} off';
  }
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
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
  return null;
}

List<Map<String, dynamic>> _readList(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
  }
  return [];
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}
