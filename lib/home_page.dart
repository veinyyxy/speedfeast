import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'Common/biz_item_widget.dart';
import 'Common/product_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Color(0xFFEFEFEF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Menu buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMenuButton(Icons.favorite, 'Favorites'),
                  _buildMenuButton(Icons.history, 'History'),
                  _buildMenuButton(Icons.person, 'Following'),
                  _buildMenuButton(Icons.view_list, 'More'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Banner section
            _BannerSection(),
            const SizedBox(height: 16),
            // Horizontal scrollable section 1
            BusinessItemWidget(
              businessName: 'walmart',
              imageUrl: 'assets/images/walmart.jpg', // 替换为你的商家图片URL
              isFavorite: true, // 初始收藏状态为真
              rating: 4.5,
              deliveryTime: '10 min',
              deliveryFee: '\$0.99 Delivery Fee',
            ),
            BusinessItemWidget(
              businessName: 'costco',
              imageUrl: 'assets/images/costco.jpg',
              isFavorite: false, // 初始收藏状态为假
              rating: 3.9,
              deliveryTime: '15-20 min',
              deliveryFee: 'Free Delivery',
            ),
            _HorizontalScrollSection(
                title: 'Title',
                imagePaths: ['assets/images/pears.jpg', 'assets/images/watermelon.jpg', 'assets/images/carrots.jpg', 'assets/images/cat.jpg']
            ),
            const SizedBox(height: 16),
            // Horizontal scrollable section 2
            _HorizontalScrollSection(
                title: 'Title',
                imagePaths: ['assets/images/radish.jpg', 'assets/images/mushrooms.jpg', 'assets/images/cherries.jpg']
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(text),
      ],
    );
  }
}

class _BannerSection extends StatefulWidget {
  //const _BannerSection({super.key});

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  final PageController _pageController = PageController();
  final List<String> _bannerImages = [
    'assets/images/pears.jpg',
    'assets/images/watermelon.jpg',
    // 添加更多广告图片路径
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return _buildBannerItem(
                'Banner title ${index + 1}', // 可以根据需要修改标题
                _bannerImages[index],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,  // PageController
          count: _bannerImages.length, // 总页数
          effect: const ExpandingDotsEffect(
            activeDotColor: Colors.black, // 选中点颜色
            dotColor: Colors.grey,        // 未选中点颜色
            dotHeight: 8,                 // 点的高度
            dotWidth: 8,                  // 点的宽度
            expansionFactor: 4,           // 选中点扩大的比例
            spacing: 5.0,                 // 点之间的间距
          ),
        ),
      ],
    );
  }

  Widget _buildBannerItem(String title, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken), // 添加一个暗色滤镜使文字更清晰
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white, // 将文字颜色改为白色
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HorizontalScrollSection extends StatefulWidget {
  final String title;
  final List<String> imagePaths;

  const _HorizontalScrollSection({
    required this.title,
    required this.imagePaths,
  });

  @override
  State<_HorizontalScrollSection> createState() => _HorizontalScrollSectionState();
}

class _HorizontalScrollSectionState extends State<_HorizontalScrollSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = true;
  static const double _scrollStep = 150.0; // 每次滚动的步长

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始状态判断是否显示右侧按钮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkButtonVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkButtonVisibility();
  }

  void _checkButtonVisibility() {
    setState(() {
      _showLeftButton = _scrollController.offset > 0;
      _showRightButton = _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + _scrollStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - _scrollStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            SizedBox(
              height: 171,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.imagePaths.length,
                itemBuilder: (context, index) {
                  final productDescriptions = [
                    TextDescription(
                      "Brand Name",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextDescription(
                      "Product Name Here",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextDescription(
                      "\$19.99",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                    // 你可以在这里添加更多的 TextDescription 对象
                    // TextDescription("Extra Info", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                  ];
                  return ProductCard(
                      imagePath: widget.imagePaths[index],
                      descriptions: productDescriptions,
                    onQuantityChanged: (count) {
                      print('Quantity changed to: $count');
                      // 在这里你可以更新全局的购物车状态等
                    },
                      width: 180,
                      height: 100,
                  );
                },
              ),
            ),
            // 左边按钮
            if (_showLeftButton)
              Positioned.fill(
                left: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 40, color: Colors.black),
                    onPressed: _scrollLeft,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.white.withValues(alpha: .7)),
                    ),
                  ),
                ),
              ),
            // 右边按钮
            if (_showRightButton)
              Positioned.fill(
                right: 16,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 40, color: Colors.black),
                    onPressed: _scrollRight,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.white.withValues(alpha: .7)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}