import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import 'recent_order_page.dart';

class OrderReviewPage extends StatefulWidget {
  const OrderReviewPage({super.key, required this.order});

  final RecentOrder order;

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  final TextEditingController _commentController = TextEditingController();
  final Map<String, int> _ratingsByOrderItemId = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      if (item.orderItemId.isNotEmpty) {
        _ratingsByOrderItemId[item.orderItemId] = item.reviewRating;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReview());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReview() async {
    final response = await context.read<ServiceProvider>().fetchOrderReview(
      widget.order.id,
    );
    if (!mounted) return;

    if (response != null) {
      final review = _asMap(response['review']);
      final comment = _firstString(review, const ['comment', 'message']);
      final rawItems = review['items'];
      if (comment.isNotEmpty) {
        _commentController.text = comment;
      } else if (widget.order.reviewComment.isNotEmpty) {
        _commentController.text = widget.order.reviewComment;
      }

      if (rawItems is List) {
        for (final rawItem in rawItems) {
          final item = _asMap(rawItem);
          final orderItemId = _firstString(item, const [
            'order_item_id',
            'orderItemId',
          ]);
          final rating = _firstInt(item, const ['rating', 'stars']);
          if (orderItemId.isNotEmpty && rating > 0) {
            _ratingsByOrderItemId[orderItemId] = rating;
          }
        }
      }
    } else if (widget.order.reviewComment.isNotEmpty) {
      _commentController.text = widget.order.reviewComment;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveReview() async {
    if (!widget.order.canReview) {
      setState(() {
        _error = 'This order can be reviewed after it is completed.';
      });
      return;
    }

    final reviewableItems = widget.order.items
        .where(
          (item) => item.orderItemId.isNotEmpty && item.productId.isNotEmpty,
        )
        .toList(growable: false);
    final missingRating = reviewableItems.any(
      (item) => (_ratingsByOrderItemId[item.orderItemId] ?? 0) < 1,
    );
    if (reviewableItems.isEmpty) {
      setState(() {
        _error = 'No reviewable items were found for this order.';
      });
      return;
    }
    if (missingRating) {
      setState(() {
        _error = 'Please choose a star rating for every item.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final response = await context.read<ServiceProvider>().saveOrderReview(
      orderId: widget.order.id,
      comment: _commentController.text,
      items: reviewableItems
          .map(
            (item) => <String, dynamic>{
              'order_item_id': item.orderItemId,
              'product_id': item.productId,
              'rating': _ratingsByOrderItemId[item.orderItemId] ?? 0,
            },
          )
          .toList(growable: false),
    );
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _error =
          context.read<ServiceProvider>().lastReviewError ??
          'Review could not be saved.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order.isReviewed ? 'EDIT REVIEW' : 'REVIEW ORDER'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text(
                  widget.order.displayId,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.order.dateLabel,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (!widget.order.canReview) ...[
                  const SizedBox(height: 14),
                  _ReviewNotice(
                    icon: Icons.lock_clock_outlined,
                    message:
                        'Reviews are available after the order is completed.',
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Overall note',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 1000,
                  enabled: widget.order.canReview,
                  decoration: const InputDecoration(
                    hintText: 'Share anything about the overall experience.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Product ratings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.order.items.isEmpty)
                  _ReviewNotice(
                    icon: Icons.receipt_long_outlined,
                    message: 'No item details are available for this order.',
                  )
                else
                  ...widget.order.items.map(
                    (item) => _ReviewItemTile(
                      item: item,
                      enabled: widget.order.canReview,
                      rating: _ratingsByOrderItemId[item.orderItemId] ?? 0,
                      onChanged: (rating) {
                        setState(() {
                          _ratingsByOrderItemId[item.orderItemId] = rating;
                        });
                      },
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FilledButton.icon(
            onPressed: widget.order.canReview && !_isSaving
                ? _saveReview
                : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.star_rate_rounded),
            label: Text(_isSaving ? 'Saving...' : 'Save Review'),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewItemTile extends StatelessWidget {
  const _ReviewItemTile({
    required this.item,
    required this.enabled,
    required this.rating,
    required this.onChanged,
  });

  final RecentOrderItem item;
  final bool enabled;
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final price = item.price > 0
        ? 'CAD \$${item.price.toStringAsFixed(2)}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity}x ${item.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (price.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(price, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ],
          ),
          if (item.optionsLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.optionsLabel,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          _StarRatingInput(
            rating: rating,
            enabled: enabled && item.orderItemId.isNotEmpty,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StarRatingInput extends StatelessWidget {
  const _StarRatingInput({
    required this.rating,
    required this.enabled,
    required this.onChanged,
  });

  final int rating;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Colors.amber.shade700;
    final emptyColor = Colors.grey.shade400;

    return Row(
      children: [
        for (var index = 1; index <= 5; index += 1)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            onPressed: enabled ? () => onChanged(index) : null,
            icon: Icon(
              index <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: index <= rating ? selectedColor : emptyColor,
              size: 30,
            ),
            tooltip: '$index star${index == 1 ? '' : 's'}',
          ),
        const SizedBox(width: 8),
        Text(
          rating > 0 ? '$rating/5' : 'Select',
          style: TextStyle(
            color: rating > 0 ? Colors.grey.shade800 : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return const {};
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

String _firstString(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  return value?.toString().trim() ?? '';
}

int _firstInt(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
