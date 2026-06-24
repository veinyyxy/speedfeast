import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/order_item.dart';
import '../Common/payment_redirect.dart';
import '../Controller/service_provider.dart';
import '../MoreMenu/more_my_account_personal_info.dart';
import '../RegisterPage/phone_login_page.dart';

bool _asBool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

class DeliveryAddressSummary {
  final String id;
  final String receiverName;
  final String country;
  final String province;
  final String city;
  final String district;
  final String street;
  final String postalCode;
  final bool isDefault;

  const DeliveryAddressSummary({
    required this.id,
    required this.receiverName,
    required this.country,
    required this.province,
    required this.city,
    required this.district,
    required this.street,
    required this.postalCode,
    required this.isDefault,
  });

  factory DeliveryAddressSummary.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value?.toString().trim() ?? '';

    return DeliveryAddressSummary(
      id: text(json['address_id']),
      receiverName: text(json['receiver_name']),
      country: text(json['country']),
      province: text(json['province']),
      city: text(json['city']),
      district: text(json['district']),
      street: text(json['street']),
      postalCode: text(json['postal_code']),
      isDefault: _asBool(json['is_default']),
    );
  }

  DeliveryAddressSummary copyWith({bool? isDefault}) {
    return DeliveryAddressSummary(
      id: id,
      receiverName: receiverName,
      country: country,
      province: province,
      city: city,
      district: district,
      street: street,
      postalCode: postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get title {
    if (street.isNotEmpty) return street;
    if (receiverName.isNotEmpty) return receiverName;
    return 'Delivery Address';
  }

  String get detail {
    return [
      district,
      city,
      province,
      country,
      postalCode,
    ].where((value) => value.isNotEmpty).join(', ');
  }

  String get receiverLabel {
    return receiverName.isEmpty ? 'Receiver not set' : receiverName;
  }

  Map<String, dynamic> toShippingAddress() {
    return {
      if (receiverName.isNotEmpty) 'receiver_name': receiverName,
      if (country.isNotEmpty) 'country': country,
      if (province.isNotEmpty) 'province': province,
      if (city.isNotEmpty) 'city': city,
      if (district.isNotEmpty) 'district': district,
      if (street.isNotEmpty) 'street': street,
      if (postalCode.isNotEmpty) 'postal_code': postalCode,
    };
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => ServiceProvider(),
        child: const OrderPage(),
      ),
    );
  }
}

enum DeliveryMode { delivery, dineIn, takeout }

enum DeliveryTimeMode { merchantDecides, scheduled }

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  double _tipPercentage = 0;
  double _customTip = 0.0;
  final TextEditingController _customTipController = TextEditingController();

  bool _isAddItemButtonPressed = false;
  bool _showCustomTipInput = false;
  DeliveryMode _deliveryMode = DeliveryMode.delivery;
  DeliveryTimeMode _deliveryTimeMode = DeliveryTimeMode.merchantDecides;
  DateTime? _scheduledDeliveryTime;
  bool _isSubmittingOrder = false;
  bool _isLoadingDeliveryAddresses = false;
  List<DeliveryAddressSummary> _deliveryAddresses = [];
  DeliveryAddressSummary? _selectedDeliveryAddress;
  String _customerName = '';
  String _customerContact = '';

  static const int _businessOpenHour = 9;
  static const int _businessOpenMinute = 0;
  static const int _businessCloseHour = 22;
  static const int _businessCloseMinute = 0;

  @override
  void initState() {
    super.initState();
    _customTipController.addListener(_updateCustomTip);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final serviceProvider = context.read<ServiceProvider>();
        if (serviceProvider.hasDineInTableContext) {
          setState(() => _deliveryMode = DeliveryMode.dineIn);
        }
        _loadDeliveryAddresses();
      }
    });
  }

  @override
  void dispose() {
    _customTipController.removeListener(_updateCustomTip);
    _customTipController.dispose();
    super.dispose();
  }

  DeliveryAddressSummary? _findDeliveryAddress(
    List<DeliveryAddressSummary> addresses,
    bool Function(DeliveryAddressSummary address) test,
  ) {
    for (final address in addresses) {
      if (test(address)) return address;
    }
    return null;
  }

  String _readProfileText(Map<String, dynamic> user, List<String> keys) {
    for (final key in keys) {
      final value = user[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _buildCustomerName(Map<String, dynamic> user) {
    final firstName = _readProfileText(user, ['first_name', 'firstName']);
    final lastName = _readProfileText(user, ['last_name', 'lastName']);
    final combinedName = [
      firstName,
      lastName,
    ].where((value) => value.isNotEmpty).join(' ');
    if (combinedName.isNotEmpty) return combinedName;
    return _readProfileText(user, ['username', 'name']);
  }

  Future<void> _loadDeliveryAddresses() async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      setState(() {
        _deliveryAddresses = [];
        _selectedDeliveryAddress = null;
        _customerName = '';
        _customerContact = '';
        _isLoadingDeliveryAddresses = false;
      });
      return;
    }

    setState(() => _isLoadingDeliveryAddresses = true);
    final profileData = await serviceProvider.fetchPersonalInfo();
    if (!mounted) return;

    if (profileData == null) {
      setState(() => _isLoadingDeliveryAddresses = false);
      return;
    }

    final user = profileData['user'] is Map
        ? Map<String, dynamic>.from(profileData['user'] as Map)
        : <String, dynamic>{};
    final addresses = (profileData['addresses'] as List? ?? [])
        .whereType<Map>()
        .map(
          (address) => DeliveryAddressSummary.fromJson(
            Map<String, dynamic>.from(address),
          ),
        )
        .where((address) => address.id.isNotEmpty)
        .toList();
    final currentAddressId = _selectedDeliveryAddress?.id;
    final selectedAddress =
        _findDeliveryAddress(
          addresses,
          (address) => address.id == currentAddressId,
        ) ??
        _findDeliveryAddress(addresses, (address) => address.isDefault) ??
        (addresses.isNotEmpty ? addresses.first : null);
    final name = _buildCustomerName(user);
    final contact = _readProfileText(user, [
      'phone_number',
      'phoneNumber',
      'cell_phone',
      'phone',
      'email',
    ]);

    setState(() {
      _deliveryAddresses = addresses;
      _selectedDeliveryAddress = selectedAddress;
      _customerName = name;
      _customerContact = contact;
      _isLoadingDeliveryAddresses = false;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddressManagement() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PersonalInfoPage()));
    if (!mounted) return;
    await _loadDeliveryAddresses();
  }

  Future<void> _showNoDeliveryAddressesSheet() async {
    final shouldManage = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a delivery address before making a delivery order.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Manage Delivery Addresses'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (shouldManage == true) {
      await _openAddressManagement();
    }
  }

  Future<void> _openDeliveryAddressSelector() async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      final loginResult = await showLoginDialog(
        context,
        reason: LoginPromptReason.deliveryAddress,
      );
      if (!mounted) return;
      if (loginResult == true) {
        await _loadDeliveryAddresses();
        if (!mounted) return;
        if (_deliveryAddresses.isEmpty) {
          await _showNoDeliveryAddressesSheet();
        }
      }
      return;
    }

    if (_isLoadingDeliveryAddresses) return;
    if (_deliveryAddresses.isEmpty) {
      await _loadDeliveryAddresses();
      if (!mounted) return;
    }
    if (_deliveryAddresses.isEmpty) {
      await _showNoDeliveryAddressesSheet();
      return;
    }

    final result = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final selectedAddressId = _selectedDeliveryAddress?.id;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Delivery Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _deliveryAddresses.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final address = _deliveryAddresses[index];
                      final isSelected = address.id == selectedAddressId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildAddressIcon(address),
                        title: Text(
                          address.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          [
                            address.detail,
                            address.receiverLabel,
                          ].where((value) => value.isNotEmpty).join('\n'),
                        ),
                        isThreeLine: address.detail.isNotEmpty,
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.circle_outlined),
                        onTap: () => Navigator.pop(context, address),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'manage'),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Manage Delivery Addresses'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    if (result == 'manage') {
      await _openAddressManagement();
      return;
    }
    if (result is DeliveryAddressSummary) {
      await _selectDeliveryAddress(result);
    }
  }

  Future<void> _selectDeliveryAddress(DeliveryAddressSummary address) async {
    setState(() {
      _selectedDeliveryAddress = address;
    });
  }

  Future<void> _chooseScheduledDeliveryTime() async {
    final firstAvailable = _firstSchedulableDateTime();
    final initialDate =
        _scheduledDeliveryTime != null &&
            _scheduledDeliveryTime!.isAfter(firstAvailable)
        ? _scheduledDeliveryTime!
        : firstAvailable;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(
        firstAvailable.year,
        firstAvailable.month,
        firstAvailable.day,
      ),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (!mounted || pickedDate == null) return;

    final initialTime = TimeOfDay(
      hour: initialDate.hour,
      minute: initialDate.minute,
    );
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select delivery time',
    );
    if (!mounted || pickedTime == null) return;

    final scheduledTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final errorMessage = _scheduledDeliveryTimeError(scheduledTime);
    if (errorMessage != null) {
      _showSnackBar(errorMessage);
      return;
    }

    setState(() {
      _deliveryTimeMode = DeliveryTimeMode.scheduled;
      _scheduledDeliveryTime = scheduledTime;
    });
  }

  void _updateCustomTip() {
    final value = double.tryParse(_customTipController.text);
    setState(() {
      _customTip = value ?? 0.0;
      _tipPercentage = -1;
    });
  }

  void _updateQuantity(String id, int delta) {
    context.read<ServiceProvider>().updateQuantity(id, delta);
  }

  double get subtotal => context.read<ServiceProvider>().cartSubtotal;
  double get deliveryFee => 4.25;
  double get deliveryServiceFee => 2.02;
  double get taxes => subtotal * 0.13;

  double get tipAmount {
    if (_tipPercentage == -1) {
      return _customTip;
    } else if (_tipPercentage > 0) {
      return subtotal * _tipPercentage;
    }
    return 0.0;
  }

  double get total {
    if (_deliveryMode == DeliveryMode.delivery) {
      return subtotal + deliveryFee + deliveryServiceFee + taxes + tipAmount;
    }
    return subtotal + taxes + tipAmount;
  }

  String get _fulfillmentTypeForRequest {
    switch (_deliveryMode) {
      case DeliveryMode.delivery:
        return 'delivery';
      case DeliveryMode.dineIn:
        return 'dine_in';
      case DeliveryMode.takeout:
        return 'takeout';
    }
  }

  Map<String, dynamic>? get _shippingAddressForRequest {
    if (_deliveryMode != DeliveryMode.delivery) return null;
    final address = _selectedDeliveryAddress;
    if (address == null || address.id.isNotEmpty) return null;
    final shippingAddress = address.toShippingAddress();
    return shippingAddress.isEmpty ? null : shippingAddress;
  }

  String? get _shippingAddressIdForRequest {
    if (_deliveryMode != DeliveryMode.delivery) return null;
    final addressId = _selectedDeliveryAddress?.id ?? '';
    return addressId.isEmpty ? null : addressId;
  }

  int get _businessOpenMinutes => _businessOpenHour * 60 + _businessOpenMinute;
  int get _businessCloseMinutes =>
      _businessCloseHour * 60 + _businessCloseMinute;

  String get _businessHoursLabel =>
      '${_formatClock(_businessOpenHour, _businessOpenMinute)} - ${_formatClock(_businessCloseHour, _businessCloseMinute)}';

  String get _deliveryTimeLabel {
    if (_deliveryTimeMode == DeliveryTimeMode.scheduled &&
        _scheduledDeliveryTime != null) {
      return 'Scheduled for ${_formatDateTime(_scheduledDeliveryTime!)}';
    }
    return 'Merchant decides after order, usually within 30 minutes.';
  }

  String? get _deliveryNoteForRequest {
    if (_deliveryMode != DeliveryMode.delivery) return null;
    if (_deliveryTimeMode == DeliveryTimeMode.scheduled) {
      final scheduledTime = _scheduledDeliveryTime;
      if (scheduledTime == null) return null;
      return 'Scheduled delivery time: ${_formatDateTime(scheduledTime)}';
    }
    return 'Delivery time preference: merchant decides after order, usually within 30 minutes.';
  }

  String _formatClock(int hour, int minute) {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }

  String _formatDateTime(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  bool _isWithinBusinessHours(DateTime value) {
    final minutes = value.hour * 60 + value.minute;
    return minutes >= _businessOpenMinutes && minutes <= _businessCloseMinutes;
  }

  DateTime _firstSchedulableDateTime() {
    final now = DateTime.now();
    final todayOpen = DateTime(
      now.year,
      now.month,
      now.day,
      _businessOpenHour,
      _businessOpenMinute,
    );
    final todayClose = DateTime(
      now.year,
      now.month,
      now.day,
      _businessCloseHour,
      _businessCloseMinute,
    );

    if (now.isBefore(todayOpen)) return todayOpen;
    final roundedNow = now.add(const Duration(minutes: 15));
    if (!roundedNow.isAfter(todayClose)) {
      return DateTime(
        roundedNow.year,
        roundedNow.month,
        roundedNow.day,
        roundedNow.hour,
        roundedNow.minute,
      );
    }

    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      _businessOpenHour,
      _businessOpenMinute,
    );
  }

  String? _scheduledDeliveryTimeError(DateTime? value) {
    if (value == null) return 'Please select a scheduled delivery time.';
    if (value.isBefore(DateTime.now())) {
      return 'Scheduled delivery time must be in the future.';
    }
    if (!_isWithinBusinessHours(value)) {
      return 'Scheduled delivery time must be within business hours ($_businessHoursLabel).';
    }
    return null;
  }

  String? _deliveryScheduleValidationMessage(DateTime? value) {
    if (_deliveryTimeMode != DeliveryTimeMode.scheduled) return null;
    return _scheduledDeliveryTimeError(value);
  }

  String? _validateOrderContents(List<OrderItem> orderItems) {
    if (orderItems.isEmpty) return 'Please add at least one item.';
    for (final item in orderItems) {
      if (!item.isAvailable) {
        return 'Please remove unavailable items before making an order.';
      }
    }
    if (_deliveryMode == DeliveryMode.delivery &&
        _selectedDeliveryAddress == null) {
      return 'Please add a delivery address.';
    }
    final deliveryScheduleError = _deliveryScheduleValidationMessage(
      _scheduledDeliveryTime,
    );
    if (deliveryScheduleError != null) return deliveryScheduleError;
    if (_deliveryMode == DeliveryMode.dineIn) {
      final tableNumber = context.read<ServiceProvider>().dineInTableNumber;
      if (tableNumber.isEmpty) {
        return 'Please scan your table QR code before making a dine-in order.';
      }
    }
    return null;
  }

  bool _isAuthenticationError(String? message) {
    final normalized = message?.toLowerCase() ?? '';
    return normalized.contains('token') ||
        normalized.contains('unauthorized') ||
        normalized.contains('log in');
  }

  Future<void> _submitOrder(List<OrderItem> orderItems) async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before making an order.')),
      );
      final loginResult = await showLoginDialog(
        context,
        reason: LoginPromptReason.checkout,
      );
      if (!mounted) return;
      if (loginResult == true) {
        await _loadDeliveryAddresses();
      }
      return;
    }

    final errorMessage = _validateOrderContents(orderItems);
    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    setState(() => _isSubmittingOrder = true);
    try {
      final response = await serviceProvider.createOrder(
        fulfillmentType: _fulfillmentTypeForRequest,
        tableNumber: _deliveryMode == DeliveryMode.dineIn
            ? serviceProvider.dineInTableNumber
            : null,
        dineInTableId: _deliveryMode == DeliveryMode.dineIn
            ? serviceProvider.dineInTableId
            : null,
        tableToken: _deliveryMode == DeliveryMode.dineIn
            ? serviceProvider.dineInTableToken
            : null,
        pickupLocation: _deliveryMode == DeliveryMode.takeout
            ? '630 Guelph Street, Winnipeg, MB, Canada, R3M 3B2'
            : null,
        deliveryNote: _deliveryNoteForRequest,
        shippingAddressId: _shippingAddressIdForRequest,
        shippingAddress: _shippingAddressForRequest,
        tipAmount: tipAmount,
      );

      if (!mounted) return;
      if (response != null) {
        final orderId = response['order']?['order_id']?.toString() ?? '';
        if (orderId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order created successfully.')),
          );
          return;
        }

        final paymentResponse = await serviceProvider.createPayment(
          orderId: orderId,
        );
        if (!mounted) return;

        final checkoutUrl =
            paymentResponse?['checkout_url']?.toString().trim() ?? '';
        if (paymentResponse == null || checkoutUrl.isEmpty) {
          final paymentError =
              serviceProvider.lastPaymentError ??
              'Payment could not be started.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order created, but payment was not started: $paymentError',
              ),
            ),
          );
          return;
        }

        final opened = await openExternalPaymentUrl(checkoutUrl);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? 'Opening secure payment page...'
                  : 'Order created. Open this payment URL: $checkoutUrl',
            ),
          ),
        );
      } else {
        final orderError =
            serviceProvider.lastOrderError ?? 'Failed to create order.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(orderError)));

        if (_isAuthenticationError(orderError)) {
          final loginResult = await showLoginDialog(
            context,
            reason: LoginPromptReason.sessionExpired,
          );
          if (!mounted) return;
          if (loginResult == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Login successful. Please submit the order again.',
                ),
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderItems = context.watch<ServiceProvider>().cartItems;
    final bool isOrderReady = orderItems.isNotEmpty && !_isSubmittingOrder;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 4.0, // 明确设置为没有阴影
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          color: primaryColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'YOUR ORDER DETAILS',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        /*Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(10.0)),
              child: Row(
                children: [
                  const Text('0000', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(' pts', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const Text('YOUR ORDER DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 48),
          ],
        ),*/
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.red[100],
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fish Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        Text(
                          'During this time, our food may contain or come in contact with fish.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildOrderModeSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: orderItems.isEmpty
                    ? [_buildEmptyOrder()]
                    : orderItems.map((item) => _buildOrderItem(item)).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                onTapDown: (_) =>
                    setState(() => _isAddItemButtonPressed = true),
                onTapUp: (_) => setState(() => _isAddItemButtonPressed = false),
                onTapCancel: () =>
                    setState(() => _isAddItemButtonPressed = false),
                child: AnimatedScale(
                  scale: _isAddItemButtonPressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Add More Items',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supply Chain Shortages',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Some ingredients and items may be unavailable due to delayed shipments or shortages.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave a Tip',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '100% goes to your delivery driver.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTipButton('15%', subtotal * 0.15, 0.15),
                      _buildTipButton('18%', subtotal * 0.18, 0.18),
                      _buildTipButton('20%', subtotal * 0.20, 0.20),
                      _buildCustomTipButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildPriceRow(
                    'Subtotal',
                    'CAD \$${subtotal.toStringAsFixed(2)}',
                  ),
                  if (_deliveryMode == DeliveryMode.delivery) ...[
                    _buildPriceRow(
                      'Delivery Fee',
                      'CAD \$${deliveryFee.toStringAsFixed(2)}',
                    ),
                    _buildPriceRow(
                      'Delivery Service Fee',
                      'CAD \$${deliveryServiceFee.toStringAsFixed(2)}',
                    ),
                  ],
                  _buildPriceRow('Taxes', 'CAD \$${taxes.toStringAsFixed(2)}'),
                  _buildPriceRow(
                    'Tip',
                    'CAD \$${tipAmount.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 30, thickness: 1, color: Colors.grey),
                  _buildPriceRow(
                    'Total',
                    'CAD \$${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    'Copyright....................',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: isOrderReady ? () => _submitOrder(orderItems) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOrderReady ? primaryColor : Colors.grey[400],
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            _isSubmittingOrder
                ? 'Creating Order...'
                : 'Make My Order • CAD \$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressIcon(DeliveryAddressSummary address) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        address.isDefault ? Icons.home_outlined : Icons.location_on_outlined,
        color: primaryColor,
      ),
    );
  }

  // (其余代码保持不变)
  Widget _buildOrderModeSection() {
    String title;
    IconData iconData;
    switch (_deliveryMode) {
      case DeliveryMode.delivery:
        title = 'Delivery';
        iconData = Icons.delivery_dining;
        break;
      case DeliveryMode.dineIn:
        title = 'Dine-in';
        iconData = Icons.restaurant;
        break;
      case DeliveryMode.takeout:
        title = 'Takeout';
        iconData = Icons.shopping_bag;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDeliveryModeSelector(),
                const SizedBox(height: 16),
                _buildConditionalModeContent(),
              ],
            ),
          ),
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(iconData, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeSelector() {
    return Row(
      children: [
        _buildModeButton('Delivery', DeliveryMode.delivery),
        const SizedBox(width: 8),
        _buildModeButton('Dine-in', DeliveryMode.dineIn),
        const SizedBox(width: 8),
        _buildModeButton('Takeout', DeliveryMode.takeout),
      ],
    );
  }

  Widget _buildModeButton(String text, DeliveryMode mode) {
    final isSelected = _deliveryMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _deliveryMode = mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildConditionalModeContent() {
    switch (_deliveryMode) {
      case DeliveryMode.delivery:
        return _buildDeliveryDetails();
      case DeliveryMode.dineIn:
        return _buildDineInDetails();
      case DeliveryMode.takeout:
        return _buildTakeoutDetails();
    }
  }

  Widget _buildDeliveryDetails() {
    final address = _selectedDeliveryAddress;
    final hasAddress = address != null;
    final addressTitle = address?.title ?? 'No delivery address selected';
    final rawAddressDetail = address?.detail ?? '';
    final addressDetail = rawAddressDetail.isNotEmpty
        ? rawAddressDetail
        : (hasAddress ? addressTitle : 'Add an address from your account.');
    final receiverName = address?.receiverName ?? '';
    final contactLabel = [
      if (_customerName.isNotEmpty) _customerName,
      if (_customerContact.isNotEmpty) _customerContact,
    ].join(', ');

    return Column(
      children: [
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _isLoadingDeliveryAddresses
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Loading delivery address...',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addressTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  addressDetail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (hasAddress && receiverName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Receiver: $receiverName',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    TextButton.icon(
                      onPressed: _openDeliveryAddressSelector,
                      icon: Icon(
                        hasAddress
                            ? Icons.swap_horiz
                            : Icons.add_location_alt_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        hasAddress ? 'Change' : 'Add',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasAddress) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _deliveryTimeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Selected',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildDeliveryTimeCard(),
        const SizedBox(height: 10),
        _buildExpandableInfoCard(
          title: 'Your Information',
          subtitle: contactLabel.isEmpty ? '* Required' : contactLabel,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDeliveryTimeCard() {
    final isMerchantDecides =
        _deliveryTimeMode == DeliveryTimeMode.merchantDecides;
    final isScheduled = _deliveryTimeMode == DeliveryTimeMode.scheduled;
    final scheduleSubtitle = _scheduledDeliveryTime == null
        ? 'Choose date and time during business hours ($_businessHoursLabel).'
        : 'Scheduled for ${_formatDateTime(_scheduledDeliveryTime!)}';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDeliveryTimeOption(
              selected: isMerchantDecides,
              icon: Icons.storefront_outlined,
              title: 'Merchant decides after order',
              subtitle: 'Usually delivered within 30 minutes.',
              onTap: () {
                setState(() {
                  _deliveryTimeMode = DeliveryTimeMode.merchantDecides;
                });
              },
            ),
            const Divider(height: 18),
            _buildDeliveryTimeOption(
              selected: isScheduled,
              icon: Icons.event_available_outlined,
              title: 'Schedule delivery time',
              subtitle: scheduleSubtitle,
              trailingLabel: _scheduledDeliveryTime == null ? 'Set' : 'Change',
              onTap: _scheduledDeliveryTime == null
                  ? _chooseScheduledDeliveryTime
                  : () {
                      setState(() {
                        _deliveryTimeMode = DeliveryTimeMode.scheduled;
                      });
                    },
              onTrailingTap: _chooseScheduledDeliveryTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeOption({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingLabel,
    VoidCallback? onTrailingTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 22, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            if (trailingLabel != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onTrailingTap ?? onTap,
                child: Text(trailingLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDineInDetails() {
    final serviceProvider = context.watch<ServiceProvider>();
    final tableNumber = serviceProvider.dineInTableNumber;
    final hasTable = tableNumber.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A&W Restaurant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '630 Guelph Street, Winnipeg, MB, Canada, R3M 3B2',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Table Number',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              hasTable ? tableNumber : 'Not selected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasTable
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final scanned = await Navigator.pushNamed(
                    context,
                    '/dine_in_scan',
                  );
                  if (mounted && scanned == true) {
                    setState(() => _deliveryMode = DeliveryMode.dineIn);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(hasTable ? 'Change Table' : 'Scan Table'),
              ),
            ),
            if (hasTable) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: serviceProvider.clearDineInTableContext,
                child: const Text('Clear'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTakeoutDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup at A&W',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '630 Guelph Street, Winnipeg, MB, Canada, R3M 3B2',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Ready in 15-20 minutes',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableInfoCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final isUnavailable = !item.isAvailable;
    final statusMessage = isUnavailable
        ? (item.availabilityMessage.isEmpty
              ? 'This item is no longer available.'
              : item.availabilityMessage)
        : item.priceChanged
        ? item.availabilityMessage
        : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isUnavailable
            ? BorderSide(color: Colors.red.shade200)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: item.resolveImageProvider(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x ${item.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  if (item.selectedOptions.values.any(
                    (values) => values.isNotEmpty,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.selectedOptions.entries
                            .where((entry) => entry.value.isNotEmpty)
                            .map(
                              (entry) =>
                                  '${entry.key}: ${entry.value.join(", ")}',
                            )
                            .join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  if (item.specialInstructions.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Note: ${item.specialInstructions.trim()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  TextButton(
                    onPressed: () => _updateQuantity(item.id, -item.quantity),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        color: isUnavailable
                            ? Colors.red.shade700
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isUnavailable
                                ? Icons.error_outline
                                : Icons.info_outline,
                            size: 14,
                            color: isUnavailable
                                ? Colors.red.shade700
                                : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: TextStyle(
                                color: isUnavailable
                                    ? Colors.red.shade700
                                    : Colors.orange.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              isUnavailable
                  ? 'Unavailable'
                  : 'CAD \$${(item.quantity * item.price).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUnavailable ? Colors.red.shade700 : Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            if (isUnavailable)
              Icon(Icons.block, color: Colors.red.shade700)
            else
              Row(
                children: [
                  _buildQuantityButton(
                    Icons.remove,
                    () => _updateQuantity(item.id, -1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildQuantityButton(
                    Icons.add,
                    () => _updateQuantity(item.id, 1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 44, color: Colors.grey[500]),
          const SizedBox(height: 10),
          const Text(
            'Your order is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Add items from the menu to start your order.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: Colors.grey[700]),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTipButton(String label, double amount, double percentage) {
    bool isSelected = _tipPercentage == percentage;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipPercentage = percentage;
            _customTipController.clear();
            _customTip = 0.0;
            _showCustomTipInput = false;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withAlpha(18) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : Colors.black,
                ),
              ),
              Text(
                'CAD \$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? primaryColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipButton() {
    bool isSelected = _tipPercentage == -1;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipPercentage = -1;
            _showCustomTipInput = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withAlpha(18) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Custom',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : Colors.black,
                ),
              ),
              _showCustomTipInput
                  ? SizedBox(
                      height: 20,
                      child: TextField(
                        controller: _customTipController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autofocus: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'CAD \$0.00',
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.7)
                                : Colors.grey[400],
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryColor : Colors.grey[700],
                        ),
                      ),
                    )
                  : Text(
                      _customTip > 0
                          ? 'CAD \$${_customTip.toStringAsFixed(2)}'
                          : ' ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? primaryColor : Colors.grey[700],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
