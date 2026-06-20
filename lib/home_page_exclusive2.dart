import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'Common/reward_widget.dart';
import 'Common/product_category_list.dart';
import 'Controller/service_provider.dart';
import 'RegisterPage/phone_login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  Color _appBarColor = Colors.transparent;
  int _selectedIndex = 0;

  // 购物车按钮位置
  Offset? _fabPosition;

  // 新增：一个用于存储动态生成 widget 列表的状态变量
  final List<Widget> _dynamicSliverWidgets = [];
  bool _isInitDataLoaded = false; // 用于确保 didChangeDependencies 中的逻辑只运行一次

  static const String _restaurantName = 'SpeedFeast Restaurant';
  static const String _restaurantAddress =
      '630 Guelph Street, Winnipeg, MB, Canada';
  static const String _restaurantPostalCode = 'R3M 3B2';
  static const String _restaurantPhone = '+1 (204) 555-0138';
  static const bool _showSearchButton = false;
  static const double _cartFabWidth = 96;
  static const double _cartFabHeight = 56;
  static const double _cartFabMargin = 16;

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
                final productId =
                    itemDataDynamic['product_id']?.toString() ?? '';
                if (productId.isEmpty || productId.toLowerCase() == 'null') {
                  continue;
                }
                items.add(
                  Product2ItemData.fromJson(
                    itemDataDynamic,
                    imageRoot: serviceProvider.fetchImageRoot(),
                  ),
                );
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
    }

    // 初始化按钮位置（如果尚未设置）
    if (_fabPosition == null) {
      final mediaQuery = MediaQuery.of(context);
      _fabPosition = _defaultFabPosition(mediaQuery.size, mediaQuery.padding);
    }
  }

  Offset _defaultFabPosition(Size size, EdgeInsets padding) {
    return _clampFabPosition(
      Offset(
        size.width - _cartFabWidth - _cartFabMargin,
        size.height -
            padding.bottom -
            kBottomNavigationBarHeight -
            _cartFabHeight -
            _cartFabMargin,
      ),
      size,
      padding,
    );
  }

  Offset _clampFabPosition(Offset position, Size size, EdgeInsets padding) {
    final maxX = size.width - _cartFabWidth - _cartFabMargin;
    final maxY =
        size.height -
        padding.bottom -
        kBottomNavigationBarHeight -
        _cartFabHeight -
        _cartFabMargin;
    final minY = padding.top + _cartFabMargin;

    return Offset(
      position.dx.clamp(_cartFabMargin, maxX),
      position.dy.clamp(minY, maxY),
    );
  }

  Offset _effectiveFabPosition(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return _clampFabPosition(
      _fabPosition ?? _defaultFabPosition(mediaQuery.size, mediaQuery.padding),
      mediaQuery.size,
      mediaQuery.padding,
    );
  }

  void _checkRegistrationStatus(BuildContext context) async {
    // 使用 Provider 获取 ServiceProvider 实例
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    final bool isLoggedIn = serviceProvider.isLoggedIn; // 替换为您的实际检查逻辑

    if (!isLoggedIn) {
      // 如果用户未登录，则显示注册提示对话框
      showDialog(
        context: context,
        barrierDismissible: false, // 用户必须选择一个选项，不能随意点击外部关闭
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Welcome to SpeedFeast!'),
            content: const Text(
              'Register now to unlock exclusive features, save your orders, and enjoy a personalized experience.',
            ),
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
                  Navigator.of(
                    context,
                  ).pushNamed('register/mobile_number_page');
                },
              ),
              ElevatedButton(
                child: const Text('Login Now'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // 关闭对话框
                  showLoginDialog(context);
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

  void _showAboutUsDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'About Us',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _restaurantName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 14),
              _AboutInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: _restaurantAddress,
              ),
              SizedBox(height: 12),
              _AboutInfoRow(
                icon: Icons.local_post_office_outlined,
                label: 'Postal Code',
                value: _restaurantPostalCode,
              ),
              SizedBox(height: 12),
              _AboutInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: _restaurantPhone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAccountStatusTap(bool isLoggedIn) async {
    if (!isLoggedIn) {
      final loggedIn = await showLoginDialog(context);
      if (!mounted) return;
      if (loggedIn == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully.')),
        );
      }
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Signed in'),
                subtitle: const Text('Your account is active on this device.'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Personal Info'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, '/more_page/personal_info');
                },
              ),
              ListTile(
                leading: const Icon(Icons.more_horiz),
                title: const Text('More Menu'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, '/more_page');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmSignOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to use your account features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<ServiceProvider>().logoutUser();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Signed out.')));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
        break;
      case 1:
        setState(() => _selectedIndex = 1);
        await Navigator.pushNamed(context, '/order_page/recent_orders');
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
        break;
      case 2:
        setState(() => _selectedIndex = 0);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('您点击了：扫码')));
        break;
      case 3:
        setState(() => _selectedIndex = 3);
        await Navigator.pushNamed(context, '/more_page');
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
        break;
    }
  }

  Widget _buildSliverListItem(BuildContext context, int index) {
    if (index < _dynamicSliverWidgets.length) {
      return _dynamicSliverWidgets[index];
    }
    return const SizedBox.shrink(); // 防止越界
  }

  Widget _buildAccountStatusChip({
    required bool isLoggedIn,
    required bool useDarkText,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isLoggedIn
        ? primaryColor.withValues(alpha: useDarkText ? 0.12 : 0.9)
        : Colors.black.withValues(alpha: useDarkText ? 0.08 : 0.25);
    final foregroundColor = isLoggedIn
        ? (useDarkText ? primaryColor : Colors.white)
        : (useDarkText ? Colors.black87 : Colors.white);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _handleAccountStatusTap(isLoggedIn),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLoggedIn ? Icons.verified_user : Icons.person_outline,
                  size: 17,
                  color: foregroundColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isLoggedIn ? 'Signed in' : 'Guest',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isLoggedIn = context.watch<ServiceProvider>().isLoggedIn;
    final cartCount = context.watch<ServiceProvider>().cartCount;
    final useDarkAppBarText = _appBarColor.computeLuminance() > 0.5;
    final cartFabPosition = _effectiveFabPosition(context);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                title: const Text(
                  'SpeedFeast',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: <Widget>[
                  _buildAccountStatusChip(
                    isLoggedIn: isLoggedIn,
                    useDarkText: useDarkAppBarText,
                  ),
                  const SizedBox(width: 6),
                  if (_showSearchButton)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('搜索功能待实现')),
                          );
                        },
                        tooltip: 'Search',
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ).copyWith(right: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: _showAboutUsDialog,
                      tooltip: 'About us',
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset('assets/images/sushi.jpg', fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black45],
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
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  return _buildSliverListItem(context, index);
                }, childCount: _dynamicSliverWidgets.length),
              ),
            ],
          ),
          Positioned(
            left: cartFabPosition.dx,
            top: cartFabPosition.dy,
            child: Draggable(
              feedback: Opacity(
                opacity: 0.8,
                child: FloatingActionButton.extended(
                  onPressed: null,
                  backgroundColor: primaryColor,
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: Text(
                    '$cartCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                final mediaQuery = MediaQuery.of(context);
                setState(() {
                  _fabPosition = _clampFabPosition(
                    details.offset,
                    mediaQuery.size,
                    mediaQuery.padding,
                  );
                });
              },
              child: FloatingActionButton.extended(
                heroTag: 'draggable_cart_fab',
                onPressed: () {
                  Navigator.pushNamed(context, '/order_page');
                },
                backgroundColor: primaryColor,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  '$cartCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(
            context,
          ).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(
            context,
          ).bottomNavigationBarTheme.unselectedItemColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Order',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
