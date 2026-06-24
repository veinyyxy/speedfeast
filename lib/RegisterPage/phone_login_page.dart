import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';

enum LoginPromptReason {
  general,
  account,
  checkout,
  recentOrders,
  deliveryAddress,
  sessionExpired,
}

class _LoginPromptCopy {
  final String title;
  final String subtitle;
  final String buttonLabel;

  const _LoginPromptCopy({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });
}

_LoginPromptCopy _copyForReason(LoginPromptReason reason) {
  switch (reason) {
    case LoginPromptReason.account:
      return const _LoginPromptCopy(
        title: 'Sign in to your account',
        subtitle: 'Manage your profile, saved addresses, and payment options.',
        buttonLabel: 'Sign in',
      );
    case LoginPromptReason.checkout:
      return const _LoginPromptCopy(
        title: 'Sign in to place your order',
        subtitle:
            'We will link this order to your account and keep your order history.',
        buttonLabel: 'Sign in and continue',
      );
    case LoginPromptReason.recentOrders:
      return const _LoginPromptCopy(
        title: 'Sign in to view your orders',
        subtitle:
            'Track recent orders, review completed orders, and check order status.',
        buttonLabel: 'Sign in',
      );
    case LoginPromptReason.deliveryAddress:
      return const _LoginPromptCopy(
        title: 'Sign in to use saved addresses',
        subtitle: 'Choose from your saved delivery addresses or add a new one.',
        buttonLabel: 'Sign in',
      );
    case LoginPromptReason.sessionExpired:
      return const _LoginPromptCopy(
        title: 'Please sign in again',
        subtitle: 'Your session expired. Sign in again to continue securely.',
        buttonLabel: 'Sign in again',
      );
    case LoginPromptReason.general:
      return const _LoginPromptCopy(
        title: 'Sign in to SpeedFeast',
        subtitle:
            'Access saved orders, addresses, rewards, and faster checkout.',
        buttonLabel: 'Sign in',
      );
  }
}

Future<bool?> showLoginDialog(
  BuildContext context, {
  LoginPromptReason reason = LoginPromptReason.general,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DualModeLoginDialogContent(reason: reason),
          ),
        ),
      );
    },
  );
}

class DualModeLoginDialogContent extends StatefulWidget {
  const DualModeLoginDialogContent({
    super.key,
    this.reason = LoginPromptReason.general,
  });

  final LoginPromptReason reason;

  @override
  State<DualModeLoginDialogContent> createState() =>
      _DualModeLoginDialogContentState();
}

class _DualModeLoginDialogContentState
    extends State<DualModeLoginDialogContent> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _completePhoneNumber = '';
  String _selectedDialCode = '+1';
  bool _isPasswordVisible = false;
  bool _isLoggingIn = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizedPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('+')) {
      return '+${trimmed.substring(1).replaceAll(RegExp(r'\D'), '')}';
    }
    return trimmed.replaceAll(RegExp(r'\D'), '');
  }

  String _phoneNumberForLogin() {
    if (_completePhoneNumber.trim().isNotEmpty) {
      return _normalizedPhone(_completePhoneNumber);
    }

    final localDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (localDigits.isEmpty) return '';
    return _normalizedPhone('$_selectedDialCode$localDigits');
  }

  String? _validatePhone(PhoneNumber? phone) {
    final rawValue = phone?.number.trim() ?? _phoneController.text.trim();
    if (rawValue.isEmpty) {
      return 'Enter your phone number.';
    }

    final completeNumber =
        phone?.completeNumber.trim() ?? _phoneNumberForLogin();
    final digits = completeNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  String _friendlyError(ServiceProvider serviceProvider) {
    final rawError = serviceProvider.lastLoginError?.trim();
    if (rawError == null || rawError.isEmpty) {
      return 'We could not sign you in. Check your phone number and password.';
    }

    final normalized = rawError.toLowerCase();
    if (normalized.contains('network')) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    if (normalized.contains('security keys') ||
        normalized.contains('configured')) {
      return 'The app is still loading. Please try again in a moment.';
    }
    if (normalized.contains('unauthorized') ||
        normalized.contains('invalid') ||
        normalized.contains('password') ||
        normalized.contains('401')) {
      return 'That phone number and password do not match.';
    }

    return rawError;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _errorMessage = '';
    });

    try {
      final serviceProvider = context.read<ServiceProvider>();
      final loginSuccess = await serviceProvider.loginUser(
        cellPhone: _phoneNumberForLogin(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (loginSuccess) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = _friendlyError(serviceProvider);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Something went wrong while signing in. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  void _openCreateAccount() {
    final navigator = Navigator.of(context);
    navigator.pop(false);
    Future<void>.delayed(Duration.zero, () {
      navigator.pushNamed('register/mobile_number_page');
    });
  }

  void _continueAsGuest() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final copy = _copyForReason(widget.reason);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                copy.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                copy.subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _isLoggingIn
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode: 'CA',
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '204 555 0123',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validatePhone,
                      onChanged: (phone) {
                        _completePhoneNumber = phone.completeNumber;
                      },
                      onCountryChanged: (country) {
                        _selectedDialCode = '+${country.dialCode}';
                        final localDigits = _phoneController.text.replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        _completePhoneNumber = localDigits.isEmpty
                            ? ''
                            : '$_selectedDialCode$localDigits';
                      },
                      enabled: !_isLoggingIn,
                      disableLengthCheck: true,
                      disableAutoFillHints: false,
                      dropdownIcon: const Icon(Icons.arrow_drop_down),
                      dropdownIconPosition: IconPosition.trailing,
                      flagsButtonPadding: const EdgeInsets.only(left: 10),
                      dropdownTextStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _isPasswordVisible
                              ? 'Hide password'
                              : 'Show password',
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: _isLoggingIn
                              ? null
                              : () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _isLoggingIn ? null : _login(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password.';
                        }
                        return null;
                      },
                      enabled: !_isLoggingIn,
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoggingIn ? null : _login,
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(copy.buttonLabel),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _isLoggingIn ? null : _openCreateAccount,
                          child: const Text('Create account'),
                        ),
                        Container(
                          width: 1,
                          height: 16,
                          color: colorScheme.outlineVariant,
                        ),
                        TextButton(
                          onPressed: _isLoggingIn ? null : _continueAsGuest,
                          child: const Text('Continue as guest'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    return MaterialApp(
      title: 'Login Dialog Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Login Demo')),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await showLoginDialog(context);
            final message = result == true
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
