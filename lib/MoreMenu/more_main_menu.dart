import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/service_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MoreMainMenu());
  }
}

class MoreMainMenu extends StatelessWidget {
  const MoreMainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'MORE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        //backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: MoreScreen(),
    );
  }
}

class MoreScreen extends StatelessWidget {
  MoreScreen({super.key});

  // 定义菜单项数据
  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Personal Info',
      'icon': Icons.person_outline,
      'action': (BuildContext context) =>
          Navigator.pushNamed(context, '/more_page/personal_info'), // 示例点击响应函数
    },
    {
      'title': 'Payment Options',
      'icon': Icons.credit_card,
      'action': (BuildContext context) => Navigator.pushNamed(
        context,
        '/more_page/payment_options/payment_list',
      ),
    },
    {
      'title': 'Recent Orders',
      'icon': Icons.assignment,
      'action': (BuildContext context) =>
          Navigator.pushNamed(context, '/order_page/recent_orders'),
    },
    {
      'title': 'Points Activity',
      'icon': Icons.star_border,
      'action': (BuildContext context) =>
          Navigator.pushNamed(context, '/more_page/rewards_activity'),
    },
    {
      'title': 'About Rewards',
      'icon': Icons.radio_button_checked,
      'action': (BuildContext context) => debugPrint('About Rewards clicked!'),
    },
    {
      'title': 'Marketing Notifications',
      'icon': Icons.notifications_none,
      'action': (BuildContext context) =>
          debugPrint('Marketing Notifications clicked!'),
    },
    {
      'title': 'Get Help',
      'icon': Icons.help_outline,
      'action': (BuildContext context) => debugPrint('Get Help clicked!'),
    },
    {
      'title': 'Legal',
      'icon': Icons.description,
      'action': (BuildContext context) => debugPrint('Legal clicked!'),
    },
  ];

  // 退出登录按钮的点击响应函数
  Future<void> _onSignOut(BuildContext context) async {
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

    if (confirmed != true || !context.mounted) return;
    await context.read<ServiceProvider>().logoutUser();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Signed out.')));
  }

  void _onSignIn(BuildContext context) {
    Navigator.pushNamed(context, '/register_page/sign_up');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return InkWell(
                  onTap: () => item['action'](context), // 绑定点击响应函数
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: <Widget>[
                        Icon(item['icon'], size: 28),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 18.0,
                              //color: Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          //color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(
                //color: Colors.grey,
                height: 1,
              ), // 添加分割线
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50.0,
              child: Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  final bool isLoggedIn = serviceProvider.isLoggedIn;
                  return OutlinedButton(
                    onPressed: () =>
                        isLoggedIn ? _onSignOut(context) : _onSignIn(context),
                    child: Text(
                      isLoggedIn ? 'Sign out' : 'Sign In / Sign Up',
                      style: const TextStyle(fontSize: 18.0),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
