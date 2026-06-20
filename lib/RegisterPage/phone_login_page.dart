import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/service_provider.dart';

// Define the login mode enumeration
enum LoginMode {
  password, // Login with password
  otp, // Login with One-Time Password (Verification Code)
}

// Function to display the login dialog
Future<bool?> showLoginDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return const AlertDialog(
        // Style is handled externally, so keep it clean here
        title: Text('User Login'),
        content: DualModeLoginDialogContent(),
      );
    },
  );
}

// Core Stateful Widget for the dialog content
class DualModeLoginDialogContent extends StatefulWidget {
  const DualModeLoginDialogContent({super.key});

  @override
  State<DualModeLoginDialogContent> createState() =>
      _DualModeLoginDialogContentState();
}

class _DualModeLoginDialogContentState
    extends State<DualModeLoginDialogContent> {
  // Initial login mode
  LoginMode _currentMode = LoginMode.password;

  // Text editing controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  bool _isPasswordVisible = false;
  Timer? _timer;
  int _countdownSeconds = 60;
  bool _isSendingOtp = false;
  bool _isLoggingIn = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Toggle login mode
  void _toggleLoginMode() {
    setState(() {
      _currentMode = _currentMode == LoginMode.password
          ? LoginMode.otp
          : LoginMode.password;
      _errorMessage = ''; // Clear error message on mode switch
    });
  }

  // Start countdown timer
  void _startCountdown() {
    setState(() {
      _isSendingOtp = false;
      _countdownSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  // Simulate sending OTP logic
  void _sendOtp() async {
    // Prevent sending if countdown is active
    if (_countdownSeconds > 0 && _countdownSeconds < 60) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSendingOtp = true;
        _errorMessage = '';
      });

      // TODO: Replace with actual OTP sending API call
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate network delay

      setState(() {
        _isSendingOtp = false;
      });

      // Assuming successful sending
      if (!_isSendingOtp) {
        _startCountdown();
      }
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _errorMessage = '';
    });

    try {
      bool loginSuccess = false;
      if (_currentMode == LoginMode.password) {
        final serviceProvider = context.read<ServiceProvider>();
        loginSuccess = await serviceProvider.loginUser(
          cellPhone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // TODO: Replace with actual OTP verification API call.
        await Future.delayed(const Duration(seconds: 2));
        if (_phoneController.text == '13800000000' &&
            _otpController.text == '654321') {
          loginSuccess = true;
        }
      }

      if (!mounted) return;
      if (loginSuccess) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = _currentMode == LoginMode.password
              ? 'Incorrect phone number or password.'
              : 'Incorrect phone number or verification code.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double dialogWidth = 300.0;

    return SizedBox(
      width: dialogWidth,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 1. Phone Number Input
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number cannot be empty.';
                }
                if (value.length < 11) {
                  return 'Please enter a valid phone number.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16.0),

            // 2. Dynamic Input Field (Password or OTP)
            if (_currentMode == LoginMode.password)
              // Password Login Mode
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password cannot be empty.';
                  }
                  return null;
                },
              )
            else
              // OTP Login Mode
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        hintText: 'Enter the SMS code',
                        prefixIcon: Icon(Icons.vpn_key),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Code cannot be empty.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Send OTP Button (with countdown)
                  ElevatedButton(
                    onPressed: _countdownSeconds == 60 || _countdownSeconds == 0
                        ? _sendOtp
                        : null,
                    child: _isSendingOtp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _countdownSeconds == 0 || _countdownSeconds == 60
                                ? 'Send Code'
                                : 'Resend ($_countdownSeconds s)',
                          ),
                  ),
                ],
              ),

            // 3. Error Message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24.0),

            // 4. Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoggingIn ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                child: _isLoggingIn
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('LOG IN', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 8.0),

            // 5. Mode Toggle Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoggingIn ? null : _toggleLoginMode,
                child: Text(
                  _currentMode == LoginMode.password
                      ? 'Use Verification Code Login'
                      : 'Use Password Login',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 独立测试代码：一个完整的 Flutter 应用
// =========================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Login Dialog Demo', home: const HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Login Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Display the login dialog and wait for the result
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => const AlertDialog(
                title: Text('User Login'),
                content: DualModeLoginDialogContent(),
              ),
            );

            // Handle the login result
            String message = result == true
                ? 'Login Successful!'
                : 'Login Cancelled or Failed.';

            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          child: const Text('Open Login Dialog'),
        ),
      ),
    );
  }
}
