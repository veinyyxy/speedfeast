import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // Pinput 的控制器
  final pinController = TextEditingController();
  // 聚焦时的节点
  final focusNode = FocusNode();
  // 表单键
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 定义默认的 pin 主题
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'APP Name',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the 4-digit code sent to you at:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),

            // Pinput 验证码输入框
            Pinput(
              controller: pinController,
              focusNode: focusNode,
              //androidSmsAutofillMethod: AndroidSmsAutofillMethod.smsUserConsentApi,
              //listenForMultipleSmsOnAndroid: true,
              length: 4,
              defaultPinTheme: defaultPinTheme,
              // 光标样式
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 2,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              onCompleted: (pin) {
                debugPrint('onCompleted: $pin');
                // 在这里处理验证码输入完成后的逻辑
                // 例如：验证 pin
              },
              onChanged: (value) {
                debugPrint('onChanged: $value');
              },
            ),

            const SizedBox(height: 16),
            Text(
              'Tip: Make sure to check your inbox and spam folders',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // 重发按钮
            ElevatedButton(
              onPressed: () {
                // 处理重发验证码的逻辑
                debugPrint('Resend code tapped!');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Resend',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const Spacer(),

            // 底部导航按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Opacity(
                  opacity: 1.0,
                  child: FloatingActionButton(
                    heroTag: "backBtn",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.grey[200],
                    elevation: 0,
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                FloatingActionButton.extended(
                  heroTag: "nextBtn",
                  onPressed: null, // 初始禁用
                  label: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}