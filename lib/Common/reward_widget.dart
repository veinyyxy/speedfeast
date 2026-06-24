import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import '../RegisterPage/phone_login_page.dart';
import 'horizontal_scroll_section.dart';

class RewardWidget extends StatefulWidget {
  const RewardWidget({super.key});

  @override
  State<RewardWidget> createState() => _RewardWidgetState();
}

class _RewardWidgetState extends State<RewardWidget> {
  bool _isExpanded = false;
  bool? _lastLoggedIn;
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
  final VoidCallback onRefresh;
  final VoidCallback onHide;

  const _RewardsSection({
    required this.rewards,
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
        HorizontalScrollSection(
          title: '$selectedPoints pts Rewards',
          items: currentRewards
              .asMap()
              .entries
              .map((entry) => entry.value.toProductItem(entry.key))
              .toList(growable: false),
          compact: true,
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
  final String imagePath;

  const _RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.imagePath,
  });

  factory _RewardItem.fromJson(Map<String, dynamic> json) {
    final pointsCost =
        _readInt(json, const ['points_cost', 'pointsCost', 'cost', 'points']) ??
        0;
    final imagePath = _readString(json, const [
      'asset_image_path',
      'assetImagePath',
      'image_path',
      'imagePath',
    ]);

    return _RewardItem(
      id: _readString(json, const ['reward_id', 'rewardId', 'id']) ?? '',
      title:
          _readString(json, const ['title', 'name', 'reward_name']) ??
          'Reward Item',
      description:
          _readString(json, const ['description', 'reward_type', 'type']) ??
          'Reward',
      pointsCost: pointsCost,
      imagePath: _localRewardAsset(imagePath, pointsCost),
    );
  }

  ProductItemData toProductItem(int index) {
    return ProductItemData(
      imagePath: imagePath,
      brandName: '$pointsCost pts',
      productName: title,
      price: '$pointsCost pts',
    );
  }

  static String _localRewardAsset(String? imagePath, int pointsCost) {
    if (imagePath != null &&
        imagePath.isNotEmpty &&
        imagePath.startsWith('assets/')) {
      return imagePath;
    }

    final fallbacks = [
      'assets/images/pears.jpg',
      'assets/images/watermelon.jpg',
      'assets/images/carrots.jpg',
      'assets/images/mushrooms.jpg',
      'assets/images/cherries.jpg',
      'assets/images/radish.jpg',
    ];
    return fallbacks[pointsCost.abs() % fallbacks.length];
  }
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
