import 'package:flutter/material.dart';
// TODO: 请根据你的项目结构，修改为正确的导入路径
import 'expandable_cart_button.dart';

class ProductCard2 extends StatelessWidget {
  final String name;
  final String price;
  final String description;
  final String? imageUrl;
  final int initialCount; // New: To set the initial quantity on the button
  final Function(int count) onQuantityChanged; // New: Callback for quantity changes
  final VoidCallback onTap;

  const ProductCard2({
    super.key,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
    required this.initialCount, // Required: initial quantity
    required this.onQuantityChanged, // Required: new callback
    required this.onTap,
  });

  // The _buildAddButton method is no longer needed.

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          // MODIFIED: Replaced with ExpandableCartButton
                          child: ExpandableCartButton(
                            initialCount: initialCount,
                            onQuantityChanged: onQuantityChanged,
                            heroTagPrefix: name, // Using item name as a unique prefix
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      // MODIFIED: Replaced with ExpandableCartButton
                      child: ExpandableCartButton(
                        initialCount: initialCount,
                        onQuantityChanged: onQuantityChanged,
                        heroTagPrefix: name, // Using item name as a unique prefix
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