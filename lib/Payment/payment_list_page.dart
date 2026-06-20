import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _handledInitialAction = false;
  String? _selectedPaymentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPaymentMethods());
  }

  Future<void> _loadPaymentMethods() async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Please log in to manage payment methods.');
      return;
    }

    setState(() => _isLoading = true);
    final methods = await serviceProvider.fetchPaymentMethods();
    if (!mounted) return;

    setState(() {
      _paymentMethods
        ..clear()
        ..addAll(methods);
      _selectedPaymentId = null;
      for (final method in _paymentMethods) {
        if (method['is_default'] == true) {
          _selectedPaymentId = method['payment_method_id']?.toString();
          break;
        }
      }
      _selectedPaymentId ??= _paymentMethods.isNotEmpty
          ? _paymentMethods.first['payment_method_id']?.toString()
          : null;
      _isLoading = false;
    });

    await _openInitialEditorIfNeeded();
  }

  Future<void> _openInitialEditorIfNeeded() async {
    if (_handledInitialAction || !mounted) return;
    _handledInitialAction = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final openType = args is Map ? args['open']?.toString() : null;
    if (openType == 'card') {
      await _openCardEditor();
    } else if (openType == 'paypal') {
      await _openPaypalEditor();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectPaymentMethod(String id) async {
    setState(() {
      _selectedPaymentId = id;
      for (final method in _paymentMethods) {
        method['is_default'] = method['payment_method_id']?.toString() == id;
      }
    });

    final success = await context
        .read<ServiceProvider>()
        .setDefaultPaymentMethod(id);
    if (!mounted) return;
    if (!success) {
      _showSnackBar('Failed to update default payment method.');
      await _loadPaymentMethods();
    }
  }

  Future<bool> _confirmAndDelete(String id) async {
    if (id.isEmpty) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: const Text('Remove this payment method from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    final success = await context.read<ServiceProvider>().deletePaymentMethod(
      id,
    );
    if (!mounted) return false;
    if (!success) {
      _showSnackBar('Failed to delete payment method.');
      return false;
    }

    _showSnackBar('Payment method deleted.');
    return true;
  }

  Future<void> _deletePaymentMethod(String id) async {
    final deleted = await _confirmAndDelete(id);
    if (!mounted) return;
    if (deleted) {
      await _loadPaymentMethods();
    }
  }

  Future<void> _openPaymentTypeChooser() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit or debit card'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 'card'),
            ),
            ListTile(
              leading: const Icon(Icons.paypal),
              title: const Text('PayPal'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 'paypal'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || type == null) return;
    if (type == 'card') {
      await _openCardEditor();
    } else if (type == 'paypal') {
      await _openPaypalEditor();
    }
  }

  Future<void> _openEditor(Map<String, dynamic> method) async {
    if (method['method_type'] == 'paypal') {
      await _openPaypalEditor(method: method);
    } else {
      await _openCardEditor(method: method);
    }
  }

  Future<void> _openCardEditor({Map<String, dynamic>? method}) async {
    final result = await _showCardEditor(method: method);
    if (result == null || !mounted) return;

    if (result.deleteRequested) {
      await _deletePaymentMethod(
        method?['payment_method_id']?.toString() ?? '',
      );
      return;
    }

    setState(() => _isSaving = true);
    final response = await context
        .read<ServiceProvider>()
        .saveCardPaymentMethod(
          paymentMethodId: method?['payment_method_id']?.toString(),
          cardNumber: result.cardNumber,
          cardLast4: result.cardLast4,
          cardBrand: result.cardBrand,
          cardExpMonth: result.expMonth,
          cardExpYear: result.expYear,
          billingCountry: result.billingCountry,
          billingPostalCode: result.billingPostalCode,
          displayLabel: result.displayLabel,
          isDefault: result.isDefault,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response == null) {
      _showSnackBar('Failed to save card.');
      return;
    }

    _showSnackBar(method == null ? 'Card added.' : 'Card updated.');
    await _loadPaymentMethods();
  }

  Future<void> _openPaypalEditor({Map<String, dynamic>? method}) async {
    final result = await _showPaypalEditor(method: method);
    if (result == null || !mounted) return;

    if (result.deleteRequested) {
      await _deletePaymentMethod(
        method?['payment_method_id']?.toString() ?? '',
      );
      return;
    }

    setState(() => _isSaving = true);
    final response = await context
        .read<ServiceProvider>()
        .savePaypalPaymentMethod(
          paymentMethodId: method?['payment_method_id']?.toString(),
          paypalEmail: result.paypalEmail,
          displayLabel: result.displayLabel,
          isDefault: result.isDefault,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response == null) {
      _showSnackBar('Failed to save PayPal.');
      return;
    }

    _showSnackBar(method == null ? 'PayPal added.' : 'PayPal updated.');
    await _loadPaymentMethods();
  }

  Future<_CardFormResult?> _showCardEditor({
    Map<String, dynamic>? method,
  }) async {
    final isEditing = method != null;
    final cardNumberController = TextEditingController();
    final expController = TextEditingController(
      text: isEditing
          ? _formatExpiryForInput(
              method['card_exp_month'],
              method['card_exp_year'],
            )
          : '',
    );
    final countryController = TextEditingController(
      text: method?['billing_country']?.toString() ?? 'CA',
    );
    final postalCodeController = TextEditingController(
      text: method?['billing_postal_code']?.toString() ?? '',
    );
    final labelController = TextEditingController(
      text: method?['display_label']?.toString() ?? '',
    );
    bool isDefault = method?['is_default'] == true || _paymentMethods.isEmpty;
    String? errorText;

    final result = await showModalBottomSheet<_CardFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void submit() {
              final exp = _parseExpiry(expController.text);
              final digits = _digitsOnly(cardNumberController.text);

              if (!isEditing && digits.length < 12) {
                setSheetState(() => errorText = 'Card number is required.');
                return;
              }
              if (digits.isNotEmpty &&
                  (digits.length < 12 || digits.length > 19)) {
                setSheetState(() => errorText = 'Card number is invalid.');
                return;
              }
              if (exp == null) {
                setSheetState(() => errorText = 'Expiration date is invalid.');
                return;
              }

              Navigator.pop(
                context,
                _CardFormResult(
                  cardNumber: digits.isEmpty ? null : digits,
                  cardLast4: method?['card_last4']?.toString(),
                  cardBrand: method?['card_brand']?.toString(),
                  expMonth: exp.month,
                  expYear: exp.year,
                  billingCountry: countryController.text.trim().isEmpty
                      ? 'CA'
                      : countryController.text.trim().toUpperCase(),
                  billingPostalCode: postalCodeController.text.trim(),
                  displayLabel: labelController.text.trim(),
                  isDefault: isDefault,
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Edit Card' : 'Add Card',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          _CardNumberInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          hintText: isEditing
                              ? 'Leave blank to keep ending ${method['card_last4'] ?? ''}'
                              : 'xxxx xxxx xxxx xxxx',
                          prefixIcon: const Icon(Icons.credit_card),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: expController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _CardExpirationInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Exp. Date',
                                hintText: 'MM/YY',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: countryController,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                hintText: 'CA',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: postalCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Nickname',
                          hintText: 'Work card',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isDefault,
                        onChanged: (value) {
                          setSheetState(() => isDefault = value ?? false);
                        },
                        title: const Text('Default payment method'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      if (isEditing) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                const _CardFormResult.delete(),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove Card'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(isEditing ? 'Save Card' : 'Add Card'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    cardNumberController.dispose();
    expController.dispose();
    countryController.dispose();
    postalCodeController.dispose();
    labelController.dispose();
    return result;
  }

  Future<_PaypalFormResult?> _showPaypalEditor({
    Map<String, dynamic>? method,
  }) async {
    final isEditing = method != null;
    final emailController = TextEditingController(
      text: method?['paypal_email']?.toString() ?? '',
    );
    final labelController = TextEditingController(
      text: method?['display_label']?.toString() ?? 'PayPal',
    );
    bool isDefault = method?['is_default'] == true || _paymentMethods.isEmpty;
    String? errorText;

    final result = await showModalBottomSheet<_PaypalFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void submit() {
              final email = emailController.text.trim();
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                setSheetState(
                  () => errorText = 'Valid PayPal email is required.',
                );
                return;
              }

              Navigator.pop(
                context,
                _PaypalFormResult(
                  paypalEmail: email,
                  displayLabel: labelController.text.trim(),
                  isDefault: isDefault,
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Edit PayPal' : 'Add PayPal',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'PayPal Email',
                          prefixIcon: Icon(Icons.paypal),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Nickname',
                          hintText: 'Personal PayPal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isDefault,
                        onChanged: (value) {
                          setSheetState(() => isDefault = value ?? false);
                        },
                        title: const Text('Default payment method'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      if (isEditing) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                const _PaypalFormResult.delete(),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove PayPal'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(isEditing ? 'Save PayPal' : 'Add PayPal'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    emailController.dispose();
    labelController.dispose();
    return result;
  }

  _Expiry? _parseExpiry(String value) {
    final digits = _digitsOnly(value);
    if (digits.length != 4) return null;
    final month = int.tryParse(digits.substring(0, 2));
    final year = int.tryParse(digits.substring(2, 4));
    if (month == null || year == null || month < 1 || month > 12) {
      return null;
    }

    final fullYear = 2000 + year;
    final now = DateTime.now();
    if (fullYear < now.year || (fullYear == now.year && month < now.month)) {
      return null;
    }

    return _Expiry(month, fullYear);
  }

  String _formatExpiryForInput(dynamic monthValue, dynamic yearValue) {
    final month = int.tryParse(monthValue?.toString() ?? '');
    final year = int.tryParse(yearValue?.toString() ?? '');
    if (month == null || year == null) return '';
    return '${month.toString().padLeft(2, '0')}/${(year % 100).toString().padLeft(2, '0')}';
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _paymentTitle(Map<String, dynamic> method) {
    final label = method['display_label']?.toString();
    if (label != null && label.trim().isNotEmpty) return label;
    return method['method_type'] == 'paypal' ? 'PayPal' : 'Card';
  }

  String _paymentValue(Map<String, dynamic> method) {
    if (method['method_type'] == 'paypal') {
      return method['paypal_email']?.toString() ?? '';
    }

    final brand = method['card_brand']?.toString() ?? 'Card';
    final last4 = method['card_last4']?.toString() ?? '';
    final exp = _formatExpiryForInput(
      method['card_exp_month'],
      method['card_exp_year'],
    );
    return '$brand ending in $last4${exp.isEmpty ? '' : ' · Exp $exp'}';
  }

  IconData _paymentIcon(Map<String, dynamic> method) {
    return method['method_type'] == 'paypal' ? Icons.paypal : Icons.credit_card;
  }

  Widget _buildPaymentTile(Map<String, dynamic> method) {
    final id = method['payment_method_id']?.toString() ?? '';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmAndDelete(id),
      onDismissed: (_) async {
        await _loadPaymentMethods();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedPaymentId == id
                ? primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: ListTile(
          leading: Icon(_paymentIcon(method), color: primaryColor),
          title: Text(
            _paymentTitle(method),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(_paymentValue(method)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () => _deletePaymentMethod(id),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _openEditor(method),
              ),
            ],
          ),
          selected: _selectedPaymentId == id,
          onTap: () => _selectPaymentMethod(id),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentMethods.isEmpty) {
      return Center(
        child: Text(
          'No payment methods yet.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentMethods,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) =>
            _buildPaymentTile(_paymentMethods[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Methods'),
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isSaving)
            Container(
              color: Colors.black.withAlpha(20),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _openPaymentTypeChooser,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFormResult {
  final bool deleteRequested;
  final String? cardNumber;
  final String? cardLast4;
  final String? cardBrand;
  final int expMonth;
  final int expYear;
  final String billingCountry;
  final String billingPostalCode;
  final String displayLabel;
  final bool isDefault;

  const _CardFormResult({
    required this.cardNumber,
    required this.cardLast4,
    required this.cardBrand,
    required this.expMonth,
    required this.expYear,
    required this.billingCountry,
    required this.billingPostalCode,
    required this.displayLabel,
    required this.isDefault,
  }) : deleteRequested = false;

  const _CardFormResult.delete()
    : deleteRequested = true,
      cardNumber = null,
      cardLast4 = null,
      cardBrand = null,
      expMonth = 1,
      expYear = 2099,
      billingCountry = '',
      billingPostalCode = '',
      displayLabel = '',
      isDefault = false;
}

class _PaypalFormResult {
  final bool deleteRequested;
  final String paypalEmail;
  final String displayLabel;
  final bool isDefault;

  const _PaypalFormResult({
    required this.paypalEmail,
    required this.displayLabel,
    required this.isDefault,
  }) : deleteRequested = false;

  const _PaypalFormResult.delete()
    : deleteRequested = true,
      paypalEmail = '',
      displayLabel = '',
      isDefault = false;
}

class _Expiry {
  final int month;
  final int year;

  const _Expiry(this.month, this.year);
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CardExpirationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    final text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
