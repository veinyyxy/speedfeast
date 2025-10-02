import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:provider/provider.dart';
//import '../Controller/service_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 1. 添加 TextEditingController 来控制邮箱输入框
  final TextEditingController _emailController = TextEditingController();
  // 2. 添加 GlobalKey<FormState> 用于管理表单状态
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // 释放 TextEditingController，避免内存泄漏
    _emailController.dispose();
    super.dispose();
  }

  // 辅助函数：校验电子邮件格式
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address.';
    }
    // 简单的电子邮件格式正则表达式
    // 匹配如 user@example.com 的格式
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null; // 验证通过
  }

  @override
  Widget build(BuildContext context) {
    //final serviceProvider = context.read<ServiceProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form( // 3. 将包含输入框的 Column 包装在 Form widget 中
              key: _formKey, // 将 GlobalKey 赋值给 Form
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  const Center(
                    child: Text(
                      'SpeedFeast',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  const Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Enter your email to sign up for this app',
                    style: TextStyle(
                      fontSize: 16,
                      //color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 邮箱输入框 - 改为 TextFormField
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'email@domain.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      errorBorder: OutlineInputBorder( // 添加错误边框样式
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder( // 添加焦点时的错误边框样式
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                    ),
                    validator: _validateEmail, // 4. 指定校验函数
                  ),

                  const SizedBox(height: 16),

                  // "Continue" 按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 5. 在点击按钮时，先进行表单校验
                        if (_formKey.currentState!.validate()) {
                          final String enteredEmail = _emailController.text;
                          // 如果表单校验通过
                          // 然后则执行导航操作
                          Navigator.of(context).pushNamed(
                            '/register/VerificationPage',
                            arguments: {
                              'email': enteredEmail
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "or" 分隔线
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // "Continue with Google" 按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 添加Google登录逻辑
                      },
                      icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                      label: const Text('Continue with Google'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0, // 去掉阴影
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // "Continue with Apple" 按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 添加Apple登录逻辑
                      },
                      icon: const FaIcon(FontAwesomeIcons.apple, size: 22),
                      label: const Text('Continue with Apple'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 服务条款和隐私政策
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        children: [
                          const TextSpan(
                              text: 'By clicking continue, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                                color: Colors.black, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: 跳转到服务条款页面
                                print('Navigate to Terms of Service');
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                                color: Colors.black, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: 跳转到隐私政策页面
                                print('Navigate to Privacy Policy');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}