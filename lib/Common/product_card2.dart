import 'package:flutter/material.dart';
import 'expandable_cart_button.dart'; // 确保这个文件存在

class ProductCard2 extends StatefulWidget {
  final String id;
  final String name;
  final String price;
  final String description;
  final String? imageUrl; // imageUrl 可以是 null
  final int initialCount;
  final Function(int count) onQuantityChanged;
  final VoidCallback onTap;
  final bool isAvailable;
  final String unavailableLabel;
  final double ratingAverage;
  final int ratingCount;

  const ProductCard2({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl, // 允许 imageUrl 为 null
    required this.initialCount,
    required this.onQuantityChanged,
    required this.onTap,
    this.isAvailable = true,
    this.unavailableLabel = 'Unavailable',
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  @override
  State<ProductCard2> createState() => _ProductCard2State();
}

class _ProductCard2State extends State<ProductCard2> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant ProductCard2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFailed = false;
    }
  }

  bool get _canTryImage {
    final source = widget.imageUrl?.trim() ?? '';
    if (source.isEmpty) return false;
    if (source.startsWith('assets/')) return true;

    final uri = Uri.tryParse(source);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _hideImageAfterError() {
    if (_imageFailed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _imageFailed = true);
      }
    });
  }

  Widget _buildProductImage(double imageOpacity) {
    final source = widget.imageUrl!.trim();

    Widget image;
    if (source.startsWith('assets/')) {
      image = Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _hideImageAfterError();
          return const SizedBox.shrink();
        },
      );
    } else {
      image = Image.network(
        source,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _hideImageAfterError();
          return const SizedBox.shrink();
        },
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Opacity(opacity: imageOpacity, child: image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showImage = _canTryImage && !_imageFailed;
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = widget.isAvailable
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.46);
    final secondaryColor = widget.isAvailable
        ? Colors.grey[700]
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final imageOpacity = widget.isAvailable ? 1.0 : 0.38;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isAvailable
                                  ? Colors.grey[600]
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.34,
                                    ),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                            if (widget.ratingCount > 0) ...[
                              const SizedBox(width: 10),
                              Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: widget.isAvailable
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.ratingAverage.toStringAsFixed(1)} (${widget.ratingCount})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (showImage || widget.isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomRight,
                        children: [
                          if (showImage) _buildProductImage(imageOpacity),
                          if (!widget.isAvailable && showImage)
                            Positioned(
                              left: 6,
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.68),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.unavailableLabel,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.isAvailable)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: ExpandableCartButton(
                                initialCount: widget.initialCount,
                                onQuantityChanged: widget.onQuantityChanged,
                                heroTagPrefix: widget.name,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
