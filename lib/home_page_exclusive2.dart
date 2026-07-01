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
  Color _appBarColor = Colors.white;
  int _selectedIndex = 0;

  // 购物车按钮位置
  Offset? _fabPosition;

  // 新增：一个用于存储动态生成 widget 列表的状态变量
  final List<Widget> _dynamicSliverWidgets = [];
  bool _isInitDataLoaded = false; // 用于确保 didChangeDependencies 中的逻辑只运行一次

  static const bool _showSearchButton = false;
  static const double _cartFabWidth = 148;
  static const double _cartFabHeight = 58;
  static const double _cartFabMargin = 16;
  static const double _homeSectionGap = 8;
  static const double _homeHeaderExpandedHeight = 190;
  static const List<String> _fulfillmentOptions = [
    'Delivery',
    'Dine-in',
    'Takeout',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitDataLoaded) {
      final serviceProvider = context.read<ServiceProvider>();
      // 假设 initData 是 Map<String, List<Map<String, dynamic>>>
      final Map<String, dynamic>? initData = serviceProvider.initData;

      _dynamicSliverWidgets.add(RewardWidget());

      if (initData != null) {
        var hasRenderedCategory = false;
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
            if (hasRenderedCategory) {
              _dynamicSliverWidgets.add(const _CategorySectionDivider());
            }
            // 添加 ProductCategoryList 到动态列表
            _dynamicSliverWidgets.add(
              ProductCategoryList(
                categoryName: categoryName, // 分类名来自Map的键
                items: items,
              ),
            );
            hasRenderedCategory = true;
          }
        });
        if (hasRenderedCategory) {
          _dynamicSliverWidgets.add(const SizedBox(height: 16));
        }
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

  void _scrollListener() {
    if (_appBarColor == Colors.white) return;
    setState(() => _appBarColor = Colors.white);
  }

  void _showAboutUsDialog() {
    final storeProfile = context.read<ServiceProvider>().storeProfileConfig;

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeProfile.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _AboutInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: storeProfile.addressDisplay,
              ),
              const SizedBox(height: 12),
              _AboutInfoRow(
                icon: Icons.local_post_office_outlined,
                label: 'Postal Code',
                value: storeProfile.postalCode,
              ),
              const SizedBox(height: 12),
              _AboutInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: storeProfile.phone,
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
      final loggedIn = await showLoginDialog(
        context,
        reason: LoginPromptReason.account,
      );
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
        final isLoggedIn = context.read<ServiceProvider>().isLoggedIn;
        await Navigator.pushNamed(
          context,
          isLoggedIn ? '/order_page/recent_orders' : '/order_page',
        );
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
        break;
      case 2:
        setState(() => _selectedIndex = 2);
        final scanned = await Navigator.pushNamed(context, '/dine_in_scan');
        if (mounted) {
          setState(() => _selectedIndex = 0);
          if (scanned == true) {
            final tableNumber = context
                .read<ServiceProvider>()
                .dineInTableNumber;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dine-in table $tableNumber is ready.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
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

  Widget _buildHomeHeaderBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 68, 16, _homeSectionGap),
          child: Column(
            children: [
              _buildRestaurantStatusStrip(colorScheme),
              const SizedBox(height: _homeSectionGap),
              _buildFulfillmentSelector(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantStatusStrip(ColorScheme colorScheme) {
    final serviceProvider = context.watch<ServiceProvider>();
    final storeProfile = serviceProvider.storeProfileConfig;
    final restaurantStatus = serviceProvider.restaurantStatusLabel;
    final isRestaurantOpen = serviceProvider.businessHoursConfig.isOpenNow;
    final normalizedStatus = restaurantStatus.toLowerCase();
    final statusColor = isRestaurantOpen
        ? const Color(0xFF21A663)
        : normalizedStatus.contains('closed')
        ? Colors.red.shade700
        : Colors.orange.shade800;

    return Material(
      color: colorScheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showAboutUsDialog,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _buildStoreLogo(serviceProvider, colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storeProfile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            restaurantStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                color: colorScheme.primary.withValues(alpha: 0.85),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreLogo(
    ServiceProvider serviceProvider,
    ColorScheme colorScheme,
  ) {
    final logoUrl = serviceProvider.storeLogoUrl;
    final logoAlt = serviceProvider.storeProfileConfig.logoAlt;
    final child = logoUrl.isEmpty
        ? _buildStoreLogoFallback(colorScheme)
        : logoUrl.startsWith('assets/')
        ? Image.asset(
            logoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: logoAlt,
            errorBuilder: (context, error, stackTrace) =>
                _buildStoreLogoFallback(colorScheme),
          )
        : Image.network(
            logoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: logoAlt,
            errorBuilder: (context, error, stackTrace) =>
                _buildStoreLogoFallback(colorScheme),
          );

    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildStoreLogoFallback(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.storefront_outlined,
        color: colorScheme.primary,
        size: 22,
      ),
    );
  }

  Widget _buildFulfillmentSelector(ColorScheme colorScheme) {
    final selectedFulfillmentType = context
        .watch<ServiceProvider>()
        .selectedFulfillmentType;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: List.generate(_fulfillmentOptions.length, (index) {
          final label = _fulfillmentOptions[index];
          final fulfillmentType = _fulfillmentTypeForLabel(label);
          return Expanded(
            child: _buildFulfillmentOption(
              label: label,
              isSelected: selectedFulfillmentType == fulfillmentType,
              colorScheme: colorScheme,
              onTap: () => context
                  .read<ServiceProvider>()
                  .setSelectedFulfillmentType(fulfillmentType),
            ),
          );
        }),
      ),
    );
  }

  String _fulfillmentTypeForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'dine-in':
        return 'dine_in';
      case 'takeout':
        return 'takeout';
      default:
        return 'delivery';
    }
  }

  Widget _buildFulfillmentOption({
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final serviceProvider = context.watch<ServiceProvider>();
    final isLoggedIn = serviceProvider.isLoggedIn;
    final cartCount = serviceProvider.cartCount;
    final cartSubtotal = serviceProvider.cartSubtotal;
    final cartFabPosition = _effectiveFabPosition(context);

    return Scaffold(
      extendBody: true,
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
                expandedHeight: _homeHeaderExpandedHeight,
                toolbarHeight: 64,
                surfaceTintColor: Colors.white,
                shadowColor: Colors.black12,
                floating: false,
                pinned: true,
                elevation: 0,
                forceElevated: false,
                automaticallyImplyLeading: false,
                leadingWidth: 190,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
                  child: Image.asset(
                    'assets/icons/SpeedFeast_main.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                titleSpacing: 0,
                actions: <Widget>[
                  _buildAccountStatusChip(
                    isLoggedIn: isLoggedIn,
                    useDarkText: true,
                  ),
                  const SizedBox(width: 12),
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
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHomeHeaderBackground(context),
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
                child: _CartFloatingButton(
                  primaryColor: primaryColor,
                  cartCount: cartCount,
                  cartSubtotal: cartSubtotal,
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
              child: _CartFloatingButton(
                primaryColor: primaryColor,
                cartCount: cartCount,
                cartSubtotal: cartSubtotal,
                onPressed: () {
                  Navigator.pushNamed(context, '/order_page');
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.white.withValues(alpha: 0.5),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: Theme.of(
                  context,
                ).bottomNavigationBarTheme.selectedItemColor,
                unselectedItemColor: Theme.of(
                  context,
                ).bottomNavigationBarTheme.unselectedItemColor,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
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
          ),
        ),
      ),
    );
  }
}

class _CategorySectionDivider extends StatelessWidget {
  const _CategorySectionDivider();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final lineColor = primaryColor.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.04),
          border: Border(
            top: BorderSide(color: lineColor),
            bottom: BorderSide(color: lineColor),
          ),
        ),
        child: const SizedBox(width: double.infinity, height: 8),
      ),
    );
  }
}

class _CartFloatingButton extends StatelessWidget {
  const _CartFloatingButton({
    required this.primaryColor,
    required this.cartCount,
    required this.cartSubtotal,
    this.onPressed,
  });

  final Color primaryColor;
  final int cartCount;
  final double cartSubtotal;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final countLabel = cartCount > 99 ? '99+' : cartCount.toString();
    final currencyCode = context
        .watch<ServiceProvider>()
        .orderPricingConfig
        .currency;

    return SizedBox(
      width: _HomePageState._cartFabWidth,
      height: _HomePageState._cartFabHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: primaryColor,
              elevation: 6,
              shadowColor: primaryColor.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned(
                              left: 0,
                              bottom: 3,
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                            Positioned(
                              right: -2,
                              top: -4,
                              child: _CartCountBadge(label: countLabel),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '$currencyCode \$${cartSubtotal.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartCountBadge extends StatelessWidget {
  const _CartCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.05,
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
