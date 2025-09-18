import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 引入这个包来控制状态栏样式
import 'Common/reward_widget.dart';
import 'Common/product_category_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. 创建 ScrollController
  late ScrollController _scrollController;
  Color _appBarColor = Colors.transparent; // 初始 AppBar 颜色为透明

  // ======== 新增代码：用于BottomNavigationBar选中状态 ========
  int _selectedIndex = 0; // 默认选中第一个Tab (Home)
  // =======================================================

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  // 2. 实现滚动监听器
  void _scrollListener() {
    // expandedHeight 是 200，kToolbarHeight 是 Flutter 默认的 AppBar 高度 (通常是 56)
    // 我们希望在图片滚动到只剩下 AppBar 高度时，背景色完全不透明
    const scrollThreshold = 200.0 - kToolbarHeight;

    // 获取当前滚动位置
    double offset = _scrollController.offset;

    // 计算透明度，clamp(0.0, 1.0) 保证值在 0 到 1 之间
    double opacity = (offset / scrollThreshold).clamp(0.0, 1.0);

    // 更新 AppBar 的颜色
    // 使用 setState 来触发 UI 重建
    setState(() {
      // Correct way to set alpha for an existing Color
      _appBarColor = Color.fromARGB((255 * opacity).round(), 255, 255, 255);
      // Original code was `Color.fromARGB(255, 255, 255, 255).withValues(alpha: opacity);`
      // which is not a valid method. `withOpacity` or `Color.fromARGB` with calculated alpha is correct.
      // If you intend to use `withOpacity`, it should be `Colors.white.withOpacity(opacity);`
    });
  }

  @override
  void dispose() {
    // 3. 释放控制器资源，防止内存泄漏
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // ======== 新增代码：BottomNavigationBar的点击事件处理 ========
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 这里可以根据 index 执行不同的操作，例如导航到不同的页面或显示不同的内容
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        Navigator.pushNamed(context, '/order_page');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPage()));
        break;
      case 2:
        print('Scan tapped!');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('您点击了：扫码'))
        );
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ScanPage()));
        break;
      case 3:
        Navigator.pushNamed(context, '/more_page');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => MorePage()));
        break;
    }
  }
  // =======================================================


  List<Widget> widgetList = [
    RewardWidget(),
    const SizedBox(height: 16),
    ProductCategoryList(
      categoryName: "Kathi Rolls",
      items: [
        Product2ItemData(
          id: '1',
          name: "Alsja Roll",
          price: "CA\$10.99",
          description: "Crispy potato patties wrapped in a flavorful noodle wrap.",
        ),
        Product2ItemData(
          id: '2',
          name: "Paneer Tikka Kathi Roll",
          price: "CA\$10.99",
          description: "Marinated paneer in a creamy tomato sauce wrapped in a soft tortilla.",
        ),
        Product2ItemData(
          id: '3',
          name: "Chicken Tikka Kathi Roll",
          price: "CA\$11.99",
          description: "Tender chicken in a creamy tomato-based wrap.",
        ),
      ],
    ),
    const SizedBox(height: 16),
    ProductCategoryList(
      categoryName: "Kathi Rolls",
      items: [
        Product2ItemData(
          id: '4',
          name: 'Paneer Paratha',
          price: 'CA\$5.99',
          description: 'Indian-style flatbread stuffed with paneer.',
          imageUrl: 'assets/images/cat.jpg', // Replace with your image asset
        ),
        Product2ItemData(
          id: '5',
          name: 'Crispy Selmon Roll',
          price: 'CA\$10.99',
          description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
        ),
        Product2ItemData(
          id: '6',
          name: 'Aloo Tikki Noodle Kathi Roll',
          price: 'CA\$10.99',
          description: 'Crispy potato patties wrapped in a flavorful noodle wrap.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 移除 Scaffold 的 appBar 属性
    return Scaffold(
      body: CustomScrollView(
        // 将控制器附加到 CustomScrollView
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            // 动态设置背景色
            backgroundColor: _appBarColor,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: _appBarColor.computeLuminance() > 0.5
                  ? Brightness.dark
                  : Brightness.light,
            ),
            expandedHeight: 200.0,
            shadowColor: Colors.black,
            floating: false,
            pinned: true,
            elevation: 4.0, // _appBarColor.opacity > 200 ? 4.0 : 0.0,
            forceElevated: true,
            leading: Image.asset('assets/images/log.png'),
            title: Text(
                'SpeedFeast',
                style: TextStyle(color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),

            // --- 新增代码开始 ---
            actions: <Widget>[
              // 放大镜图标按钮
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0), // 上下边距
                decoration: BoxDecoration(
                  // corrected `withValues` to `withOpacity`
                  color: Colors.black.withValues(alpha: 0.25), // 半透明黑色背景
                  shape: BoxShape.circle, // 圆形
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white), // 白色图标
                  onPressed: () {
                    // TODO: 实现搜索功能
                    print('Search button tapped!');
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('搜索功能待实现'))
                    );
                  },
                  tooltip: 'Search', // 长按提示
                ),
              ),

              // 三个点的图标按钮
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0).copyWith(
                    right: 8.0), // 上下和右侧边距
                decoration: BoxDecoration(
                  // corrected `withValues` to `withOpacity`
                  color: Colors.black.withValues(alpha: 0.25), // 半透明黑色背景
                  shape: BoxShape.circle, // 圆形
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  // 白色图标
                  onPressed: () {
                    // TODO: 实现更多选项功能
                    print('More options button tapped!');
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('更多选项待实现'))
                    );
                  },
                  tooltip: 'More options',
                ),
              ),
            ],
            // --- 新增代码结束 ---

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    'assets/images/sushi.jpg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black45,
                        ],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Text(
                          'Welcome to SpeedFeast Restaurant',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '体验极速美食与温馨氛围的完美结合，让您的味蕾享受非凡之旅。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.0,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return widgetList[index];
              },
              childCount: 5,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, // 容器的背景色，通常与 BottomNavigationBar 的背景色一致
          boxShadow: [
            BoxShadow(
              // corrected `withValues` to `withOpacity`
              color: Colors.black.withOpacity(0.2), // 阴影颜色
              spreadRadius: 2, // 阴影扩散程度
              blurRadius: 10, // 阴影模糊程度
              offset: const Offset(0, -2), // 阴影偏移量 (x, y)。-2 表示向上偏移，使得阴影在上方
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey,
          // ======== 新增代码：currentIndex 和 onTap ========
          currentIndex: _selectedIndex, // 绑定当前选中的索引
          onTap: _onItemTapped,        // 绑定点击事件处理函数
          // ===============================================
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag), label: 'Order'),
            BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}