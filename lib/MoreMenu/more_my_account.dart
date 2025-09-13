import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      'action': (BuildContext context) => print('Payment Options clicked!'),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.deepOrange,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'MY ACCOUNT',
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
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
                          color: Colors.deepOrange,
                          size: 28,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(
                color: Colors.grey,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}