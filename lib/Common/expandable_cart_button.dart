import 'package:flutter/material.dart';

class ExpandableCartButton extends StatefulWidget {
  final int initialCount;
  final Function(int count) onQuantityChanged;
  final String heroTagPrefix; // 用于确保 heroTag 唯一

  const ExpandableCartButton({
    super.key,
    this.initialCount = 0,
    required this.onQuantityChanged,
    required this.heroTagPrefix,
  });

  @override
  State<ExpandableCartButton> createState() => _ExpandableCartButtonState();
}

class _ExpandableCartButtonState extends State<ExpandableCartButton> {
  late int _itemCount;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _itemCount = widget.initialCount;
    _isExpanded = _itemCount > 0;
  }

  void _increment() {
    setState(() {
      _itemCount++;
      _isExpanded = true;
      widget.onQuantityChanged(_itemCount);
    });
  }

  void _decrement() {
    setState(() {
      _itemCount--;
      if (_itemCount == 0) {
        _isExpanded = false;
      }
      widget.onQuantityChanged(_itemCount);
    });
  }

  void _handleInitialAdd() {
    setState(() {
      _itemCount = 1;
      _isExpanded = true;
      widget.onQuantityChanged(_itemCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded || _itemCount == 0) {
      // 原始加号按钮
      return FloatingActionButton(
        heroTag: '${widget.heroTagPrefix}_add_initial',
        // 组合唯一的 heroTag
        onPressed: _handleInitialAdd,
        mini: true,
        backgroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.black),
      );
    } else {
      // 展开的按钮
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2.0,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 减号按钮
            InkWell(
              onTap: _decrement,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: const Icon(Icons.remove, color: Colors.black, size: 20),
              ),
            ),
            // 数量显示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '$_itemCount',
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // 加号按钮
            InkWell(
              onTap: _increment,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      );
    }
  }
}
