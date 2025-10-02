import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'Common/reward_widget.dart';
import 'Common/product_category_list.dart';
import 'Controller/service_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  Color _appBarColor = Colors.transparent;
  int _selectedIndex = 0;

  // 新增：一个用于存储动态生成 widget 列表的状态变量
  final List<Widget> _dynamicSliverWidgets = [];
  bool _isInitDataLoaded = false; // 用于确保 didChangeDependencies 中的逻辑只运行一次

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // 在 WidgetsBinding.instance.addPostFrameCallback 中执行，
    // 确保 build 方法已经完成，context 是可用的。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRegistrationStatus(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitDataLoaded) {
      final serviceProvider = context.read<ServiceProvider>();
      // 假设 initData 是 Map<String, List<Map<String, dynamic>>>
      final Map<String, dynamic>? initData = serviceProvider.initData;

      _dynamicSliverWidgets.add(RewardWidget());
      _dynamicSliverWidgets.add(const SizedBox(height: 16));

      if (initData != null) {
        // 遍历 initData 的每个键值对，键是分类名，值是产品列表
        initData.forEach((categoryName, productListDynamic) {
          if (productListDynamic is List) {
            List<Product2ItemData> items = [];
            for (var itemDataDynamic in productListDynamic) {
              if (itemDataDynamic is Map<String, dynamic>) {
                // 根据你的JSON结构，提取对应的数据
                items.add(Product2ItemData(
                  id: itemDataDynamic['product_id'] as String,
                  name: itemDataDynamic['product_name'] as String,
                  price: itemDataDynamic['base_price'] as String,
                  description: itemDataDynamic['description'] as String,
                  imageUrl: serviceProvider.fetchImageRoot()
                      + itemDataDynamic['image_url'] as String?, // imageUrl可能为null
                ));
              }
            }
            // 添加 ProductCategoryList 到动态列表
            _dynamicSliverWidgets.add(
              ProductCategoryList(
                categoryName: categoryName, // 分类名来自Map的键
                items: items,
              ),
            );
            _dynamicSliverWidgets.add(const SizedBox(height: 16));
          }
        });
      } else {
        _dynamicSliverWidgets.add(const Text("未能加载产品分类数据或数据格式不正确."));
      }

      _isInitDataLoaded = true;
      // 如果需要在数据加载后立即更新UI，可以调用setState，但通常didChangeDependencies后会紧跟build，所以可能不需要
      // setState(() {});
    }
  }

  void _checkRegistrationStatus(BuildContext context) async {
    // 使用 Provider 获取 ServiceProvider 实例
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    // TODO: 在 ServiceProvider 中实现一个方法来检查用户是否已登录。
    // 例如：bool isLoggedIn = serviceProvider.isUserLoggedIn();
    // 这是一个示例，您需要根据您的 ServiceProvider 实际逻辑来判断。
    // 假设 ServiceProvider 有一个 `isLoggedIn` 属性或方法。
    final bool isLoggedIn = serviceProvider.isLoggedIn; // 替换为您的实际检查逻辑

    if (!isLoggedIn) {
      // 如果用户未登录，则显示注册提示对话框
      showDialog(
        context: context,
        barrierDismissible: false, // 用户必须选择一个选项，不能随意点击外部关闭
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Welcome to SpeedFeast!'),
            content: const Text('Register now to unlock exclusive features, save your orders, and enjoy a personalized experience.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Continue as Guest'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // 关闭对话框
                },
              ),
              ElevatedButton(
                child: const Text('Register Now'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // 关闭对话框
                  // 导航到注册页面
                  // 假设您有一个名为 '/register' 的路由
                  Navigator.of(context).pushNamed('register/mobile_number_page');
                  //Navigator.of(context).pushNamed('/register/sign_up_screen');
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _scrollListener() {
    const scrollThreshold = 200.0 - kToolbarHeight;
    double offset = _scrollController.offset;
    double opacity = (offset / scrollThreshold).clamp(0.0, 1.0);

    setState(() {
      _appBarColor = Color.fromARGB((255 * opacity).round(), 255, 255, 255);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        Navigator.pushNamed(context, '/order_page');
        break;
      case 2:
        print('Scan tapped!');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('您点击了：扫码'))
        );
        break;
      case 3:
        Navigator.pushNamed(context, '/more_page');
        break;
    }
  }

  // 您的 createWidgets 方法现在可以简化，因为它不再需要从 Provider 获取数据
  // 它的作用是返回一个特定的 widget，而不是整个列表
  // 不过，SliverChildBuilderDelegate 期望每个 index 返回一个 widget，而不是一个 List<Widget>
  // 所以你可能需要调整你的 SliverList 策略
  // 假设你的 _dynamicSliverWidgets 已经包含了所有需要展示的列表项
  Widget _buildSliverListItem(BuildContext context, int index) {
    if (index < _dynamicSliverWidgets.length) {
      return _dynamicSliverWidgets[index];
    }
    return const SizedBox.shrink(); // 防止越界
  }


  @override
  Widget build(BuildContext context) {
    // 如果你需要在 build 方法中监听 ServiceProvider 的变化并重建 UI，
    // 你可以在这里使用 context.watch，但通常不建议频繁地在 build 方法的顶层做复杂的逻辑
    // final data = context.watch<ServiceProvider>().initData;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
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
            elevation: 4.0,
            forceElevated: true,
            leading: Image.asset('assets/images/log.png'),
            title: Text(
                'SpeedFeast',
                style: TextStyle(color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            actions: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  // corrected `withValues` to `withOpacity`
                  color: Colors.black.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    print('Search button tapped!');
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('搜索功能待实现'))
                    );
                  },
                  tooltip: 'Search',
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0).copyWith(
                    right: 8.0),
                decoration: BoxDecoration(
                  // corrected `withValues` to `withOpacity`
                  color: Colors.black.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    print('More options button tapped!');
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('更多选项待实现'))
                    );
                  },
                  tooltip: 'More options',
                ),
              ),
            ],
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
                // 现在 SliverList 使用 _dynamicSliverWidgets 来构建子项
                return _buildSliverListItem(context, index);
              },
              // childCount 取决于 _dynamicSliverWidgets 的长度
              childCount: _dynamicSliverWidgets.length,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
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