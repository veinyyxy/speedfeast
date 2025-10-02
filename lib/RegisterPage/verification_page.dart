import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'dart:async'; // 引入 Timer
import 'package:provider/provider.dart';
import '../Controller/service_provider.dart';

class VerificationPage extends StatefulWidget {
  final String emailOrPhone; // 传入的可以是电子邮件或电话号码
  final String type; // 传入的验证码类型 (email 或 phone)
  const VerificationPage({super.key, required this.emailOrPhone, required this.type});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // Pinput 的控制器
  final pinController = TextEditingController();
  // 聚焦时的节点
  final focusNode = FocusNode();
  // 表单键 (如果将来Pinput内有其他表单元素会用到，目前可保留)
  final formKey = GlobalKey<FormState>();

  // ======= 新增的状态变量用于校验逻辑 =======
  String _verificationTypeMessage = 'email address'; // 动态显示在 UI 上的文本 (如 'email address' 或 'phone number')
  bool _isLoading = false; // 用于显示加载状态 (发送码或验证码时)
  String? _errorMessage; // 显示错误信息
  String? _successMessage; // 显示成功信息

  // 重发计时器相关
  Timer? _timer;
  int _countdownSeconds = 60; // 初始倒计时秒数

  @override
  void initState() {
    super.initState();
    _determineVerificationType(); // 页面加载时判断验证类型
    debugPrint('VerificationPage initialized with emailOrPhone: ${widget.emailOrPhone}');
    _sendInitialCode(); // 页面加载后立即尝试发送初始验证码
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel(); // 取消计时器以防止内存泄漏
    super.dispose();
  }

  // 根据传入的 emailOrPhone 判断是电子邮件还是电话号码
  void _determineVerificationType() {
    // 简单的正则表达式判断是否为电子邮件格式
    // 对于电话号码，生产环境可能需要更复杂的验证或使用像 `libphonenumber` 这样的库。
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (emailRegex.hasMatch(widget.emailOrPhone)) {
      _verificationTypeMessage = 'email address';
    } else {
      // 如果不是电子邮件格式，则假设它是电话号码
      _verificationTypeMessage = 'phone number';
    }
  }

  // 启动/重置重发倒计时
  void _startCountdown() {
    _countdownSeconds = 60; // 重置倒计时
    _timer?.cancel(); // 取消任何现有的计时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { // 确保 Widget 仍在 Widget 树中，防止在 dispose 后调用 setState
        timer.cancel();
        return;
      }
      if (_countdownSeconds == 0) {
        timer.cancel();
        setState(() {}); // 倒计时结束，重建 UI 以启用重发按钮
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  // 模拟发送初始验证码
  void _sendInitialCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // 清除之前的错误信息
      _successMessage = null; // 清除之前的成功信息
      pinController.clear(); // 清空 PIN 输入框
    });
    final serviceProvider = context.read<ServiceProvider>();
    try {
      bool res = await serviceProvider.sendVerificationCode(widget.emailOrPhone, widget.type);
      if(res) {
        if(widget.type == 'email') {
          _successMessage = 'Verification code sent to your email.';
        } else {
          _successMessage = 'Verification code sent to your phone.';
        }
      }
      else {
        _errorMessage = 'Failed to send code. Please try again.';
      }
      _startCountdown(); // 无论成功失败，都启动倒计时
    } catch (e) {
      _errorMessage = 'Failed to send code. Please try again.';
      debugPrint('Error sending code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 模拟重发验证码
  void _resendCode() async {
    if (_countdownSeconds > 0) return; // 倒计时未结束时不能重发

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      pinController.clear(); // 清空 PIN 输入框
    });
    final serviceProvider = context.read<ServiceProvider>();

    try {
      bool res = await serviceProvider.sendVerificationCode(widget.emailOrPhone, widget.type);
      if(res) {
        if(widget.type == 'email') {
          _successMessage = 'Verification code resent to your email.';
        } else {
          _successMessage = 'Verification code resent to your phone.';
        }
      }
      else {
        _errorMessage = 'Failed to send code. Please try again.';
      }
      _startCountdown(); // 重发后重新启动倒计时
    } catch (e) {
      _errorMessage = 'Failed to resend code. Please try again.';
      debugPrint('Error resending code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 模拟验证码的校验
  void _verifyCode(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null; // 清除之前的成功信息
    });
    final serviceProvider = context.read<ServiceProvider>();

    try {
      // TODO: 调用service的验证码校验功能
      bool res = await serviceProvider.verifyVerificationCode(widget.emailOrPhone, pin, widget.type);
      if(res){
        _successMessage = 'Verification successful!';
      }
      else
      {
        _errorMessage = 'Invalid code. Please try again.';
        debugPrint('Verification failed for $pin');
      }
    } catch (e) {
      _errorMessage = 'An error occurred during verification.';
      debugPrint('Error during verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    // 判断 "Next" 按钮是否应该启用
    bool isNextButtonEnabled = pinController.text.length == 4 && _successMessage == 'Verification successful!';

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
        // 添加返回按钮到 AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Enter the 4-digit code sent to your $_verificationTypeMessage:', // 动态显示是邮件还是电话
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.emailOrPhone,
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
              length: 4, // 4位数字验证码
              defaultPinTheme: defaultPinTheme,
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
                _verifyCode(pin); // 当 Pinput 完成时调用验证逻辑
              },
              onChanged: (value) {
                debugPrint('onChanged: $value');
                // 如果用户开始重新输入 PIN，清除之前的成功/错误消息
                if (value.length < 4 && (_successMessage != null || _errorMessage != null)) {
                  setState(() {
                    _successMessage = null;
                    _errorMessage = null;
                  });
                }
                // 强制重建，以便 "Next" 按钮的状态能够及时更新
                setState(() {});
              },
            ),

            const SizedBox(height: 16),
            // 根据状态显示加载、错误或成功信息
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              )
            else if (_successMessage != null)
                Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green, fontSize: 14),
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
              onPressed: _countdownSeconds == 0 ? _resendCode : null, // 倒计时结束时才能点击
              style: ElevatedButton.styleFrom(
                // 按钮前景颜色在禁用时变灰
                foregroundColor: _countdownSeconds == 0 ? Colors.black : Colors.grey[600],
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                _countdownSeconds == 0 ? 'Resend' : 'Resend in $_countdownSeconds s', // 动态显示倒计时
                style: TextStyle(
                  fontSize: 16,
                  color: _countdownSeconds == 0 ? Colors.black : Colors.grey[600], // 文本颜色在禁用时变灰
                ),
              ),
            ),

            const Spacer(),

            // 底部导航按钮 (Next button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 返回按钮
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
                // Next 按钮
                FloatingActionButton.extended(
                  heroTag: "nextBtn",
                  onPressed: isNextButtonEnabled // 根据 `isNextButtonEnabled` 动态启用/禁用
                      ? () {
                    debugPrint("Next button tapped after successful verification!");
                    // TODO: 在这里执行导航到下一个页面的逻辑
                    // 例如：Navigator.of(context).pushReplacementNamed('/set_new_password');
                  }
                      : null,
                  label: const Text(
                    'Next',
                    style: TextStyle(fontSize: 18),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  backgroundColor: isNextButtonEnabled
                      ? Theme.of(context).primaryColor // 启用时使用主题主色
                      : Colors.grey[300], // 禁用时使用灰色
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