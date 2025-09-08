import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'horizontal_scroll_section.dart';

// 这个文件包含了主要的 RewardWidget 和其内部私有的 _RewardsSection

class RewardWidget extends StatefulWidget {
  const RewardWidget({super.key});

  @override
  State<RewardWidget> createState() => _RewardWidgetState();
}

class _RewardWidgetState extends State<RewardWidget> {
  // _isExpanded 状态现在由 RewardWidget 自身管理
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: 1000 / 3000, // Current points / target points
                                      strokeWidth: 10,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                          Colors.deepOrange),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '3000',
                                    style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text('pts',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/long.jpeg',
                          height: 60,
                          width: 100,
                        ),
                      ],
                    ),
                    const Text('Unlock more items at 300'),
                    const SizedBox(height: 10),
                    if (!_isExpanded)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = true; // 展开奖励详情
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Explore Rewards',
                                style: TextStyle(color: Colors.white)),
                            SizedBox(width: 5),
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.white),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded)
          // 现在使用私有类 _RewardsSection
            _RewardsSection(
              onHide: () {
                setState(() {
                  _isExpanded = false; // 通过回调函数折叠奖励详情
                });
              },
            ),
        ],
      );
  }
}

// -----------------------------------------------------------------------------
// _RewardsSection: 从原始文件提取并重命名为私有类
// -----------------------------------------------------------------------------
// 它被标记为私有 (_RewardsSection)，因为它主要用于 RewardWidget 内部。

class _RewardsSection extends StatefulWidget { // 重命名为 _RewardsSection
  final VoidCallback onHide; // 回调函数，用于通知父组件隐藏此部分

  const _RewardsSection({required this.onHide});

  @override
  State<_RewardsSection> createState() => _RewardsSectionState(); // State class 也重命名
}

class _RewardsSectionState extends State<_RewardsSection> { // State class 也重命名
  String _selectedPoints = '300'; // 默认选中 300 点
  final List<String> _pointOptions = ['300', '600', '900', '1500']; // 可选的点数分类

  // 为每个点数类别准备一些示例奖励数据
  final Map<String, List<ProductItemData>> _rewardsData = {
    '300': [
      ProductItemData(imagePath: 'assets/images/pears.jpg', brandName: 'Fresh Farms', productName: 'Juicy Pears', price: '300 pts'),
      ProductItemData(imagePath: 'assets/images/watermelon.jpg', brandName: 'Green Valley', productName: 'Sweet Watermelon', price: '300 pts'),
      ProductItemData(imagePath: 'assets/images/carrots.jpg', brandName: 'Organic+', productName: 'Crisp Carrots', price: '300 pts'),
    ],
    '600': [
      ProductItemData(imagePath: 'assets/images/cat.jpg', brandName: 'Pet Food Co.', productName: 'Happy Cat Kibble', price: '600 pts'),
      ProductItemData(imagePath: 'assets/images/radish.jpg', brandName: 'Farm Fresh', productName: 'Spicy Radish', price: '600 pts'),
      ProductItemData(imagePath: 'assets/images/pears.jpg', brandName: 'Fresh Farms', productName: 'Juicy Pears', price: '600 pts'),
    ],
    '900': [
      ProductItemData(imagePath: 'assets/images/mushrooms.jpg', brandName: 'Gourmet', productName: 'Fresh Mushrooms', price: '900 pts'),
      ProductItemData(imagePath: 'assets/images/cherries.jpg', brandName: 'Sweet Treats', productName: 'Ripe Cherries', price: '900 pts'),
      ProductItemData(imagePath: 'assets/images/watermelon.jpg', brandName: 'Green Valley', productName: 'Sweet Watermelon', price: '900 pts'),
    ],
    '1500': [
      ProductItemData(imagePath: 'assets/images/carrots.jpg', brandName: 'Organic+', productName: 'Crisp Carrots', price: '1500 pts'),
      ProductItemData(imagePath: 'assets/images/cat.jpg', brandName: 'Pet Food Co.', productName: 'Happy Cat Kibble', price: '1500 pts'),
      ProductItemData(imagePath: 'assets/images/radish.jpg', brandName: 'Farm Fresh', productName: 'Spicy Radish', price: '1500 pts'),
      ProductItemData(imagePath: 'assets/images/cherries.jpg', brandName: 'Sweet Treats', productName: 'Ripe Cherries', price: '1500 pts'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final List<ProductItemData> currentRewards = _rewardsData[_selectedPoints] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.orange[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _pointOptions.map((points) {
                  return _buildPointButton(
                    context,
                    points,
                    isSelected: _selectedPoints == points,
                    onTap: () {
                      setState(() {
                        _selectedPoints = points;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              HorizontalScrollSection(
                title: '$_selectedPoints Reward Items',
                items: currentRewards,
                onViewMore: () {
                  if (kDebugMode) {
                    print('View more $_selectedPoints items tapped!');
                  }
                  // Handle "See All Rewards" logic for this specific point category
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle See All Rewards
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text('See All Rewards',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Handle About A&W Rewards
                  },
                  child: const Text('About Rewards',
                      style: TextStyle(color: Colors.deepOrange)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: widget.onHide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Hide',
                          style: TextStyle(color: Colors.deepOrange)),
                      SizedBox(width: 5),
                      Icon(Icons.keyboard_arrow_up, color: Colors.deepOrange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointButton(
      BuildContext context,
      String points, {
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!),
        ),
        child: Text(
          points,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}