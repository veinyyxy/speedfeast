import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        // 如果你需要按钮、浮动操作按钮等也使用 DeepOrange
        // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange),
      ),
      home: MyAccountScreen(),
    );
  }
}

class MyAccountScreen extends StatelessWidget {
  MyAccountScreen({super.key});

  // 定义菜单项数据
  final List<Map<String, dynamic>> accountItems = [
    {
      'title': 'Personal Info',
      'icon': Icons.person_outline,
      'action': (BuildContext context) => Navigator.pushNamed(context, '/more_page/my_account/personal_info'),
    },
    {
      'title': 'Payment Options',
      'icon': Icons.credit_card,
      'action': (BuildContext context) => Navigator.pushNamed(context, '/more_page/my_account/payment_options'),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'MY ACCOUNT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            ListView.separated(
              shrinkWrap: true, // 确保 ListView 只占用其内容所需的空间
              physics: const NeverScrollableScrollPhysics(), // 禁止 ListView 自身滚动
              itemCount: accountItems.length,
              itemBuilder: (context, index) {
                final item = accountItems[index];
                return InkWell(
                  onTap: () => item['action'](context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          item['icon'],
                          size: 28,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}