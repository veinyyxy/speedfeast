import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class MobileNumberPage extends StatefulWidget {
  const MobileNumberPage({super.key});

  @override
  State<MobileNumberPage> createState() => _MobileNumberPageState();
}

class _MobileNumberPageState extends State<MobileNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneNumber; // 存储完整的手机号码 (带国家码)
  bool _isNextButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkNextButtonStatus);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_checkNextButtonStatus);
    _phoneController.dispose();
    super.dispose();
  }

  void _checkNextButtonStatus() {
    setState(() {
      // 只有当手机号输入框不为空时才启用 "Next" 按钮
      _isNextButtonEnabled = _phoneController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'APP Name', // 您可以根据需要更改此处的应用名称
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
            const Text(
              'Enter your mobile number (Optional)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your mobile to aid in account recovery',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            Text(
              'Mobile',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),

            // 手机号码输入区域
            IntlPhoneField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Mobile number',
                filled: true,
                fillColor: Colors.grey[200], // 与图片中的背景色匹配
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 移除边框
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              initialCountryCode: 'CA', // 初始国家代码设置为加拿大 (CA)
              onChanged: (phone) {
                // 当手机号或国家代码改变时触发
                _phoneNumber = phone.completeNumber;
                _checkNextButtonStatus(); // 重新检查按钮状态
                if (kDebugMode) {
                  print(_phoneNumber);
                }
              },
              // 样式定制以匹配图片
              dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              dropdownIconPosition: IconPosition.trailing, // 下拉图标放在右侧
              dropdownTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
              showDropdownIcon: true,
              disableLengthCheck: true, // 允许自由输入长度，根据实际需求调整
              // 国家选择器框的样式
              dropdownDecoration: BoxDecoration(
                color: Colors.grey[200], // 与图片中的背景色匹配
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Skip 按钮
            ElevatedButton(
              onPressed: () {
                // 处理跳过逻辑
                if (kDebugMode) {
                  print('Skip tapped!');
                }
                // Navigator.push(context, MaterialPageRoute(builder: (context) => NextPage()));
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Colors.grey[200], // 文本颜色为黑色，背景颜色为浅灰色
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0, // 移除阴影
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const Spacer(), // 将底部导航按钮推到底部

            // 底部导航按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧返回按钮
                FloatingActionButton(
                  heroTag: "backBtn", // 避免多个 FloatingActionButton 的 heroTag 冲突
                  onPressed: () {
                    Navigator.pop(context); // 返回上一页
                  },
                  backgroundColor: Colors.grey[200],
                  elevation: 0,
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                // 右侧 Next 按钮
                FloatingActionButton.extended(
                  heroTag: "nextBtn", // 避免多个 FloatingActionButton 的 heroTag 冲突
                  onPressed: _isNextButtonEnabled
                      ? () {
                    // 处理 Next 逻辑
                    if (kDebugMode) {
                      print('Next tapped with phone: $_phoneNumber');
                    }
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => NextPage()));
                  }
                      : null, // 根据 _isNextButtonEnabled 决定是否禁用
                  label: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  backgroundColor: _isNextButtonEnabled ? Colors.black : Colors.grey[300], // 启用或禁用时的背景色
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ],
            ),
            const SizedBox(height: 20), // 底部留白
          ],
        ),
      ),
    );
  }
}