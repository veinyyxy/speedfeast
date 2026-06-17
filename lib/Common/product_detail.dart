import 'package:flutter/material.dart';

enum ProductOptionSelectionType { single, multiple }

class ProductDetailOption {
  final String id;
  final String title;
  final String? subtitle;
  final double extraPrice;
  final List<ProductDetailOptionGroup> childGroups;

  const ProductDetailOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.extraPrice = 0,
    this.childGroups = const [],
  });

  bool get hasChildren => childGroups.isNotEmpty;
}

class ProductDetailOptionGroup {
  final String id;
  final String title;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final ProductOptionSelectionType selectionType;
  final List<ProductDetailOption> options;

  const ProductDetailOptionGroup({
    required this.id,
    required this.title,
    required this.options,
    this.isRequired = false,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.selectionType = ProductOptionSelectionType.single,
  });

  String get ruleText {
    if (isRequired) {
      return maxSelect == 1 ? 'Select 1' : 'Select $minSelect to $maxSelect';
    }
    return maxSelect == 1 ? 'Choose 1' : 'Select up to $maxSelect';
  }
}

class ProductRecommendation {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final Map<String, List<String>> selections;

  const ProductRecommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.selections = const {},
  });
}

class ProductDetailOrderData {
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, List<String>> selections;

  const ProductDetailOrderData({
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.selections,
  });
}

class ProductDetail extends StatefulWidget {
  final String id;
  final String name;
  final String description;
  final String storeName;
  final ImageProvider imageProvider;
  final double basePrice;
  final int initialQuantity;
  final List<ProductRecommendation> recommendations;
  final List<ProductDetailOptionGroup> optionGroups;
  final ValueChanged<Map<String, List<String>>>? onSelectionChanged;
  final ValueChanged<int>? onQuantityChanged;
  final ValueChanged<ProductRecommendation?>? onRecommendationChanged;
  final ValueChanged<ProductDetailOrderData>? onAddToOrder;

  const ProductDetail({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.storeName,
    required this.imageProvider,
    required this.basePrice,
    required this.optionGroups,
    this.initialQuantity = 1,
    this.recommendations = const [],
    this.onSelectionChanged,
    this.onQuantityChanged,
    this.onRecommendationChanged,
    this.onAddToOrder,
  });

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final Map<String, Set<String>> _selectedByGroup = {};
  final ScrollController _scrollController = ScrollController();
  int _quantity = 1;
  bool _showCompactHeader = false;
  String? _selectedRecommendationId;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity < 1 ? 1 : widget.initialQuantity;
    for (final group in widget.optionGroups) {
      _selectedByGroup[group.id] = <String>{};
    }
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant ProductDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuantity != widget.initialQuantity &&
        widget.initialQuantity != _quantity) {
      _quantity = widget.initialQuantity < 1 ? 1 : widget.initialQuantity;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 190;
    if (shouldShow == _showCompactHeader) return;
    setState(() => _showCompactHeader = shouldShow);
  }

  void _toggleOption(
    ProductDetailOptionGroup group,
    ProductDetailOption option,
  ) {
    final selected = _selectedByGroup.putIfAbsent(group.id, () => <String>{});

    setState(() {
      if (group.selectionType == ProductOptionSelectionType.single) {
        selected
          ..clear()
          ..add(option.id);
      } else {
        if (selected.contains(option.id)) {
          selected.remove(option.id);
        } else if (selected.length < group.maxSelect) {
          selected.add(option.id);
        }
      }
      _syncRecommendationHighlight();
    });

    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    widget.onSelectionChanged?.call(
      _selectedByGroup.map(
        (key, value) => MapEntry(key, value.toList(growable: false)),
      ),
    );
  }

  void _clearGroupSelections(ProductDetailOptionGroup group) {
    _selectedByGroup[group.id]?.clear();
    for (final option in group.options) {
      for (final childGroup in option.childGroups) {
        _clearGroupSelections(childGroup);
      }
    }
  }

  void _clearAllSelections() {
    for (final group in widget.optionGroups) {
      _clearGroupSelections(group);
    }
  }

  bool _selectionSetsEqual(Set<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  bool _matchesRecommendation(ProductRecommendation recommendation) {
    for (final group in widget.optionGroups) {
      final expected = recommendation.selections[group.id] ?? const <String>[];
      final actual = _selectedByGroup[group.id] ?? <String>{};
      if (!_selectionSetsEqual(actual, expected)) return false;
    }
    return true;
  }

  void _syncRecommendationHighlight() {
    if (_selectedRecommendationId == null) return;

    ProductRecommendation? recommendation;
    for (final item in widget.recommendations) {
      if (item.id == _selectedRecommendationId) {
        recommendation = item;
        break;
      }
    }

    if (recommendation == null || !_matchesRecommendation(recommendation)) {
      _selectedRecommendationId = null;
      widget.onRecommendationChanged?.call(null);
    }
  }

  void _selectRecommendation(ProductRecommendation recommendation) {
    setState(() {
      if (_selectedRecommendationId == recommendation.id) {
        _selectedRecommendationId = null;
        _clearAllSelections();
        widget.onRecommendationChanged?.call(null);
      } else {
        _selectedRecommendationId = recommendation.id;
        _clearAllSelections();
        for (final entry in recommendation.selections.entries) {
          _selectedByGroup[entry.key] = entry.value.toSet();
        }
        widget.onRecommendationChanged?.call(recommendation);
      }
    });
    _notifySelectionChanged();
  }

  bool _areRequiredGroupsSatisfied(List<ProductDetailOptionGroup> groups) {
    for (final group in groups) {
      if (group.isRequired) {
        final selectedCount = _selectedByGroup[group.id]?.length ?? 0;
        if (selectedCount < group.minSelect) return false;
      }
    }
    return true;
  }

  void _showChildOptions(ProductDetailOption option) {
    if (!option.hasChildren) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, bottomSheetSetState) {
            final canConfirm = _areRequiredGroupsSatisfied(option.childGroups);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              minChildSize: 0.35,
              builder: (context, controller) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            option.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose from the available options below.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final group in option.childGroups)
                            _buildGroup(group, bottomSheetSetState),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: canConfirm
                                ? () => Navigator.pop(context)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _setQuantity(int value) {
    if (value < 1) return;
    setState(() => _quantity = value);
    widget.onQuantityChanged?.call(value);
  }

  double get _selectedExtras {
    return _calculateExtras(widget.optionGroups);
  }

  double get _finalPrice {
    return (widget.basePrice + _selectedExtras) * _quantity;
  }

  double get _unitPrice {
    return widget.basePrice + _selectedExtras;
  }

  Map<String, List<String>> get _selectedOptions {
    return _selectedByGroup.map(
      (key, value) => MapEntry(key, value.toList(growable: false)),
    );
  }

  double _calculateExtras(List<ProductDetailOptionGroup> groups) {
    double total = 0;
    for (final group in groups) {
      final selected = _selectedByGroup[group.id] ?? <String>{};
      for (final option in group.options) {
        if (selected.contains(option.id)) {
          total += option.extraPrice;
        }
        total += _calculateExtras(option.childGroups);
      }
    }
    return total;
  }

  String _formatPrice(double value) {
    return 'CA\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHero(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(),
                    _buildStoreRow(),
                    if (widget.recommendations.isNotEmpty)
                      _buildRecommendations(),
                    const Divider(height: 10, thickness: 6),
                    for (final group in widget.optionGroups) _buildGroup(group),
                    _buildSpecialInstructions(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
          _buildTopButtons(context),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 270,
      pinned: false,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Image(
          image: widget.imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported, size: 48),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    if (_showCompactHeader) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          elevation: 2,
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _roundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _roundIconButton(icon: Icons.share, onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _roundIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.maybePop(context),
            ),
            _roundIconButton(icon: Icons.share, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icon, size: 26)),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreRow() {
    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_outlined, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.storeName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your recommended options',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 20),
              itemCount: widget.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final recommendation = widget.recommendations[index];
                return _RecommendationCard(
                  recommendation: recommendation,
                  isSelected: _selectedRecommendationId == recommendation.id,
                  onTap: () => _selectRecommendation(recommendation),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    ProductDetailOptionGroup group, [
    StateSetter? externalSetState,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (group.isRequired) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Required',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ] else
                    Text(
                      'Optional',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      group.ruleText,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final option in group.options)
          _buildOptionRow(group, option, externalSetState),
        Divider(height: 10, thickness: 6, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildOptionRow(
    ProductDetailOptionGroup group,
    ProductDetailOption option,
    StateSetter? externalSetState,
  ) {
    final selected = _selectedByGroup[group.id]?.contains(option.id) ?? false;
    final isSingle = group.selectionType == ProductOptionSelectionType.single;

    return InkWell(
      onTap: () {
        _toggleOption(group, option);
        externalSetState?.call(() {});
        if (option.hasChildren) {
          _showChildOptions(option);
        }
      },
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Icon(
                isSingle
                    ? (selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked)
                    : (selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                size: 30,
                color: selected ? Colors.black : Colors.grey.shade900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      option.subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (option.extraPrice > 0)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  '+CA\$${option.extraPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (option.hasChildren) ...[
              const SizedBox(width: 14),
              const Icon(Icons.chevron_right, size: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18),
                  SizedBox(width: 7),
                  Text(
                    'Special instructions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          14 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            _quantityButton(
              icon: Icons.remove,
              enabled: _quantity > 1,
              onTap: () => _setQuantity(_quantity - 1),
            ),
            SizedBox(
              width: 44,
              child: Center(
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _quantityButton(
              icon: Icons.add,
              enabled: true,
              onTap: () => _setQuantity(_quantity + 1),
            ),
            const Spacer(),
            Text(
              _formatPrice(_finalPrice),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => widget.onAddToOrder?.call(
                ProductDetailOrderData(
                  quantity: _quantity,
                  unitPrice: _unitPrice,
                  totalPrice: _finalPrice,
                  selections: _selectedOptions,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Add to order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            icon,
            size: 32,
            color: enabled ? Colors.black : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ProductRecommendation recommendation;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          width: 320,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recommendation.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'CA\$${recommendation.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 28,
                color: isSelected ? Colors.black : Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<ProductDetailOptionGroup> _demoProductOptionGroups = [
  ProductDetailOptionGroup(
    id: 'crust',
    title: 'Crust Choice',
    isRequired: true,
    minSelect: 1,
    maxSelect: 1,
    selectionType: ProductOptionSelectionType.single,
    options: [
      ProductDetailOption(id: 'regular_crust', title: 'Regular Crust'),
      ProductDetailOption(id: 'thin_crust', title: 'Thin Crust'),
      ProductDetailOption(id: 'thick_crust', title: 'Thick Crust'),
    ],
  ),
  ProductDetailOptionGroup(
    id: 'size',
    title: 'Size Choice',
    isRequired: true,
    minSelect: 1,
    maxSelect: 1,
    selectionType: ProductOptionSelectionType.single,
    options: [
      ProductDetailOption(id: 'small', title: 'Small'),
      ProductDetailOption(id: 'medium', title: 'Medium', extraPrice: 3.99),
      ProductDetailOption(id: 'large', title: 'Large', extraPrice: 6.99),
    ],
  ),
  ProductDetailOptionGroup(
    id: 'topping',
    title: 'Topping Addition',
    isRequired: false,
    minSelect: 0,
    maxSelect: 32,
    selectionType: ProductOptionSelectionType.multiple,
    options: [
      ProductDetailOption(
        id: 'extra_sauce',
        title: 'Extra Sauce',
        extraPrice: 3.00,
      ),
      ProductDetailOption(
        id: 'parmesan_cheese',
        title: 'Parmesan Cheese',
        extraPrice: 3.00,
      ),
    ],
  ),
  ProductDetailOptionGroup(
    id: 'beverages',
    title: 'Recommended Beverages',
    isRequired: false,
    minSelect: 0,
    maxSelect: 5,
    selectionType: ProductOptionSelectionType.multiple,
    options: [
      ProductDetailOption(
        id: 'canned_pop',
        title: 'Canned Pop',
        extraPrice: 2.50,
        childGroups: [
          ProductDetailOptionGroup(
            id: 'canned_pop_flavor',
            title: 'Choose Flavor',
            isRequired: true,
            minSelect: 1,
            maxSelect: 1,
            selectionType: ProductOptionSelectionType.single,
            options: [
              ProductDetailOption(id: 'cola', title: 'Cola'),
              ProductDetailOption(id: 'diet_cola', title: 'Diet Cola'),
              ProductDetailOption(id: 'ginger_ale', title: 'Ginger Ale'),
            ],
          ),
        ],
      ),
      ProductDetailOption(
        id: 'two_litre_pop',
        title: 'Pop (2 Litre)',
        extraPrice: 5.25,
        childGroups: [
          ProductDetailOptionGroup(
            id: 'two_litre_flavor',
            title: 'Choose Flavor',
            isRequired: true,
            minSelect: 1,
            maxSelect: 1,
            selectionType: ProductOptionSelectionType.single,
            options: [
              ProductDetailOption(id: 'pepsi', title: 'Pepsi'),
              ProductDetailOption(id: 'orange', title: 'Orange Soda'),
              ProductDetailOption(id: 'root_beer', title: 'Root Beer'),
            ],
          ),
        ],
      ),
      ProductDetailOption(
        id: 'fresh_lemonade',
        title: 'Fresh Lemonade',
        extraPrice: 4.99,
      ),
    ],
  ),
];

const List<ProductRecommendation> _demoRecommendations = [
  ProductRecommendation(
    id: 'recent_regular_large',
    title: '#1 · Ordered recently by 10+ others',
    subtitle: 'Regular Crust · Large',
    price: 21.98,
    selections: {
      'crust': ['regular_crust'],
      'size': ['large'],
    },
  ),
  ProductRecommendation(
    id: 'recent_thin_medium',
    title: '#2 · Popular with pizza lovers',
    subtitle: 'Thin Crust · Medium',
    price: 18.99,
    selections: {
      'crust': ['thin_crust'],
      'size': ['medium'],
    },
  ),
  ProductRecommendation(
    id: 'recent_thick_small',
    title: '#3 · Best value pick',
    subtitle: 'Thick Crust · Small',
    price: 15.99,
    selections: {
      'crust': ['thick_crust'],
      'size': ['small'],
    },
  ),
];

// ===== STANDALONE TEST CODE START: remove this block when integrated =====
void main() {
  runApp(const _ProductDetailDemoApp());
}

class _ProductDetailDemoApp extends StatelessWidget {
  const _ProductDetailDemoApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProductDetail(
        id: 'hamberger2',
        name: 'Meaty Meat Pizza',
        description:
            'Classic pepperoni, sausage, bacon crumbles, salami, and extra cheese.',
        storeName: 'Little Italy Pizzeria and Wings',
        imageProvider: AssetImage('assets/images/hamberger2.jpg'),
        basePrice: 21.98,
        recommendations: _demoRecommendations,
        optionGroups: _demoProductOptionGroups,
      ),
    );
  }
}

// ===== STANDALONE TEST CODE END =====
