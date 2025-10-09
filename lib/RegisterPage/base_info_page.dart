import 'package:flutter/material.dart';
import '../../../Common/select_edit_box.dart';
import '../../../Common/editable_field.dart'; // 导入 EditableField widget
import '../../../Common/password_field.dart'; // 导入 PasswordField widget
import 'package:provider/provider.dart';
import '../Controller/service_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BaseInfoPage("431232345", "v@g.com"), // 将 home 改为 RegistrationPage
      // ... (theme 保持不变)
    );
  }
}

class BaseInfoPage extends StatefulWidget {
  // 重命名为 RegistrationPage
  const BaseInfoPage(String? phone, String? email, {super.key}) : _phone = phone, _email = email;
  final String? _phone;
  final String? _email;

  @override
  BaseInfoPageState createState() => BaseInfoPageState(); // 重命名状态类
}

class BaseInfoPageState extends State<BaseInfoPage> {
  // 重命名为 RegistrationPageState
  // 定义密码字段的可见性状态
  bool _showPassword = false; // 原来的 _showNewPassword
  bool _showConfirmPassword = false;

  // Controllers for editable profile fields
  // 注册页面，初始值应为空
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Controllers for password fields
  // 注册时不需要原始密码，所以 _originalPasswordController 移除
  final TextEditingController _passwordController = TextEditingController(); // 原来的 _newPasswordController
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State variable to hold the current email address, which can be modified
  late String? _currentEmail;
  late String? _currentPhone;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget._email;
    _currentPhone = widget._phone;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose(); // 销毁 _passwordController
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to show the email edit dialog
  void _showEditEmailDialog(BuildContext context) {
    // 使用局部控制器，确保每次弹窗都有独立的控制器，并在弹窗关闭后正确释放
    final TextEditingController dialogEmailController = TextEditingController(text: _currentEmail);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Email Address'),
          content: TextField(
            controller: dialogEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter new email address',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(dialogContext); // Close the dialog without saving
              },
            ),
            ElevatedButton(
              child: const Text('Ok'),
              onPressed: () {
                setState(() {
                  _currentEmail = dialogEmailController.text; // Update the email state
                });
                Navigator.pop(dialogContext); // Close the dialog
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This block runs after the dialog is completely dismissed,
      // regardless of how it was dismissed (Save, Cancel, or outside tap).
      dialogEmailController.dispose(); // Ensure the controller is disposed
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.read<ServiceProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.deepOrange,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'REGISTER', // 标题改为 REGISTER
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // 使用 EditableField widget
              EditableField(
                label: 'First Name *',
                controller: _firstNameController,
                isLocked: false,
              ),
              SizedBox(height: 10),
              EditableField(
                label: 'Last Name *',
                controller: _lastNameController,
                isLocked: false,
              ),
              SizedBox(height: 10),
              SelectEditBox(
                key: const ValueKey('phone_number_field'),
                label: 'Phone number *',
                value: _currentPhone != null ? _currentPhone! : '',
                // 注册时通常为空
                onTap: () => print('Show edit dialog for Phone number.'),
                onIconTap: () {
                  print('Show Dialog for Phone number.');
                },
              ),
              SizedBox(height: 10),
              SelectEditBox(
                key: const ValueKey('email_address_field'),
                label: 'Email Address *',
                value: _currentEmail != null ? _currentEmail! : '',
                // 注册时通常为空
                onTap: () => print('Show edit dialog for Email Address.'),
                onIconTap: () {
                  _showEditEmailDialog(context); // 点击图标时触发弹窗
                },
              ),
              SizedBox(height: 20),
              Text(
                'Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // 注册时只需要输入新密码和确认密码
              PasswordField(
                label: 'Password*', // 标签改为 Password*
                controller: _passwordController, // 使用 _passwordController
                isVisible: _showPassword,
                onToggle: (value) {
                  setState(() {
                    _showPassword = value;
                  });
                },
              ),
              SizedBox(height: 10),
              PasswordField(
                label: 'Confirm*',
                controller: _confirmPasswordController,
                isVisible: _showConfirmPassword,
                onToggle: (value) {
                  setState(() {
                    _showConfirmPassword = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Access updated values from controllers
                  debugPrint('Registering user with the following info:');
                  debugPrint('First Name: ${_firstNameController.text}');
                  debugPrint('Last Name: ${_lastNameController.text}');
                  debugPrint('Password: ${_passwordController.text}'); // 获取密码
                  debugPrint('Confirm Password: ${_confirmPasswordController
                      .text}'); // 获取确认密码
                  bool isRegisterSuccess = await serviceProvider.registerUser(
                    '${_firstNameController.text} ${_lastNameController.text}',
                    _currentPhone ?? '',
                    _currentEmail ?? '',
                    _passwordController.text);
                  // !!! 在这里添加 mounted 检查 !!!
                  if (!mounted) return; // 如果 Widget 已经被卸载，则不执行后续操作

                  if (isRegisterSuccess) {
                    // 注册成功，跳转到主页或登录页
                    debugPrint('Registration successful!');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration successful! Please log in.')),
                    );
                    // 假设你的登录页是 LoginPage，或者直接跳转到 HomePage
                    // 你需要替换为你实际的目标路由
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', // 替换为你的主页或登录页
                          (Route<dynamic> route) => false, // 移除所有之前的路由
                    );
                  } else {
                    // 注册失败
                    debugPrint('Registration failed.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration failed. Please try again.')),
                    );
                    // 可以在这里显示一个错误消息
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Register', // 按钮文本改为 Register
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// _buildAddAddressButton 函数已移除
}