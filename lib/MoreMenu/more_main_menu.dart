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
    // 建议：如果MoreMainMenu是应用的一个子页面，
    // 通常MyApp会提供一个顶层的MaterialApp和Navigator。
    // 例如：
    return MaterialApp(
      theme: ThemeData(
        // 将主色调改为 DeepOrange
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white, // Pure white background
        appBarTheme: const AppBarTheme(
          // AppBar 背景色改为 DeepOrange
          backgroundColor: Colors.white70,
          elevation: 0, // No shadow for app bar
          // AppBar 图标颜色改为白色，与 DeepOrange 背景形成对比
          iconTheme: IconThemeData(color: Colors.deepOrange),

          titleTextStyle: TextStyle(
            // AppBar 标题文字颜色改为白色
            color: Colors.deepOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.deepOrange),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.deepOrange,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepOrange,
            side: const BorderSide(color: Colors.deepOrange, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        )
        // 如果你需要按钮、浮动操作按钮等也使用 DeepOrange
        // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange),
      ),
      home: MoreMainMenu(), // 或一个主页
    );
    // 然后从SomeInitialScreen导航到MoreMainMenu
    // For demonstration, we'll keep MoreMainMenu as the root for now.
    //return MoreMainMenu();
  }
}

class MoreMainMenu extends StatelessWidget {
  const MoreMainMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          //color: Colors.deepOrange,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('MORE',
            style: TextStyle(
              //color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            )),
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
      'action': (BuildContext context) => Navigator.pushNamed(context, '/more_page/personal_info'), // 示例点击响应函数
    },
    {
      'title': 'Payment Options',
      'icon': Icons.credit_card,
      'action': (BuildContext context) => Navigator.pushNamed(context, '/more_page/payment_options/payment_list'),
    },
    {
      'title': 'Recent Orders',
      'icon': Icons.assignment,
      'action': (BuildContext context) => Navigator.pushNamed(context, '/order_page/recent_orders'),
    },
    {
      'title': 'Points Activity',
      'icon': Icons.star_border,
      'action': (BuildContext context) => print('Points Activity clicked!'),
    },
    {
      'title': 'About Rewards',
      'icon': Icons.radio_button_checked,
      'action': (BuildContext context) => print('About Rewards clicked!'),
    },
    {
      'title': 'Marketing Notifications',
      'icon': Icons.notifications_none,
      'action': (BuildContext context) => print('Marketing Notifications clicked!'),
    },
    {
      'title': 'Get Help',
      'icon': Icons.help_outline,
      'action': (BuildContext context) => print('Get Help clicked!'),
    },
    {
      'title': 'Legal',
      'icon': Icons.description,
      'action': (BuildContext context) => print('Legal clicked!'),
    },
  ];

  // 退出登录按钮的点击响应函数
  void _onSignOut(BuildContext context) {
    final serviceProvider = context.read<ServiceProvider>();
    serviceProvider.logoutUser();
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
                        Icon(
                          item['icon'],
                          //color: Colors.deepOrange,
                          size: 28,
                        ),
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
              child: OutlinedButton(
                onPressed: () => _onSignOut(context), // 绑定退出登录函数
                /*style: OutlinedButton.styleFrom(
                  side: const BorderSide(*//*color: Colors.deepOrange, *//*width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  //backgroundColor: Colors.white,
                ),*/
                child: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 18.0,
                    //color: Colors.deepOrange,
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
