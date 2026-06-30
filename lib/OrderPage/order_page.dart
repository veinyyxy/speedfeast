import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/order_item.dart';
import '../Common/payment_redirect.dart';
import '../Common/product_category_list.dart';
import '../Common/product_detail.dart';
import '../Controller/service_provider.dart';
import '../MoreMenu/more_my_account_personal_info.dart';
import '../RegisterPage/phone_login_page.dart';

bool _asBool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

String _asText(dynamic value) => value?.toString().trim() ?? '';

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
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

class RewardRedemptionSummary {
  final String id;
  final String title;
  final int pointsCost;
  final double discountAmount;
  final String currency;
  final String expiresAt;
  final String rewardType;
  final String productId;
  final String productName;

  const RewardRedemptionSummary({
    required this.id,
    required this.title,
    required this.pointsCost,
    required this.discountAmount,
    required this.currency,
    required this.expiresAt,
    required this.rewardType,
    required this.productId,
    required this.productName,
  });

  factory RewardRedemptionSummary.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] is Map
        ? Map<String, dynamic>.from(json['reward'] as Map)
        : <String, dynamic>{};
    final title = _asText(reward['title']).isNotEmpty
        ? _asText(reward['title'])
        : _asText(json['title']).isNotEmpty
        ? _asText(json['title'])
        : 'Reward Voucher';
    final pointsCost = _asInt(json['points_cost'] ?? json['pointsCost']);
    final discountAmount = _asDouble(
      json['discount_amount'] ?? json['discountAmount'],
    );
    final rewardType =
        _asText(json['reward_type'] ?? json['rewardType']).isNotEmpty
        ? _asText(json['reward_type'] ?? json['rewardType'])
        : _asText(reward['reward_type'] ?? reward['rewardType']).isNotEmpty
        ? _asText(reward['reward_type'] ?? reward['rewardType'])
        : 'discount';
    final productName =
        _asText(json['product_name'] ?? json['productName']).isNotEmpty
        ? _asText(json['product_name'] ?? json['productName'])
        : _asText(reward['product_name'] ?? reward['productName']);

    return RewardRedemptionSummary(
      id: _asText(json['redemption_id'] ?? json['redemptionId'] ?? json['id']),
      title: title,
      pointsCost: pointsCost,
      discountAmount: rewardType == 'product'
          ? 0
          : discountAmount <= 0
          ? pointsCost / 100
          : discountAmount,
      currency: _asText(json['currency']).isEmpty
          ? 'CAD'
          : _asText(json['currency']),
      expiresAt: _asText(json['expires_at'] ?? json['expiresAt']),
      rewardType: rewardType,
      productId: _asText(
        json['product_id'] ??
            json['productId'] ??
            reward['product_id'] ??
            reward['productId'],
      ),
      productName: productName,
    );
  }

  bool get isProductReward => rewardType.toLowerCase() == 'product';

  String get discountLabel =>
      '${currency.toUpperCase()} \$${discountAmount.toStringAsFixed(2)} off';

  String get valueLabel {
    if (isProductReward) {
      return productName.isEmpty
          ? 'Free product'
          : 'Free product: $productName';
    }
    return discountLabel;
  }

  String get expiresLabel {
    if (expiresAt.isEmpty) return 'No expiry set';
    final parsed = DateTime.tryParse(expiresAt);
    if (parsed == null) return 'Expires $expiresAt';
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'Expires ${local.year}-$month-$day';
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
  final TextEditingController _orderNoteController = TextEditingController();

  bool _isAddItemButtonPressed = false;
  bool _showCustomTipInput = false;
  DeliveryMode _deliveryMode = DeliveryMode.delivery;
  DeliveryTimeMode _deliveryTimeMode = DeliveryTimeMode.merchantDecides;
  DateTime? _scheduledDeliveryTime;
  bool _isSubmittingOrder = false;
  bool _isLoadingDeliveryAddresses = false;
  bool _isLoadingRewardRedemptions = false;
  List<DeliveryAddressSummary> _deliveryAddresses = [];
  List<RewardRedemptionSummary> _activeRewardRedemptions = [];
  DeliveryAddressSummary? _selectedDeliveryAddress;
  RewardRedemptionSummary? _selectedRewardRedemption;
  String _customerName = '';
  String _customerContact = '';
  String _orderNote = '';

  static const String _storeName = 'SpeedFeast Restaurant';
  static const bool _showFishAlertWarning = false;
  static const bool _showSupplyChainShortageWarning = false;

  @override
  void initState() {
    super.initState();
    _customTipController.addListener(_updateCustomTip);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final serviceProvider = context.read<ServiceProvider>();
        final initialMode = serviceProvider.hasDineInTableContext
            ? DeliveryMode.dineIn
            : _deliveryModeFromFulfillmentType(
                serviceProvider.selectedFulfillmentType,
              );
        if (_deliveryMode != initialMode) {
          setState(() => _deliveryMode = initialMode);
        }
        serviceProvider.setSelectedFulfillmentType(
          _fulfillmentTypeForDeliveryMode(initialMode),
        );
        _loadDeliveryAddresses();
        _loadRewardRedemptions();
      }
    });
  }

  @override
  void dispose() {
    _customTipController.removeListener(_updateCustomTip);
    _customTipController.dispose();
    _orderNoteController.dispose();
    super.dispose();
  }

  DeliveryMode _deliveryModeFromFulfillmentType(String fulfillmentType) {
    switch (fulfillmentType.trim().toLowerCase().replaceAll('-', '_')) {
      case 'dine_in':
        return DeliveryMode.dineIn;
      case 'takeout':
      case 'take_out':
        return DeliveryMode.takeout;
      default:
        return DeliveryMode.delivery;
    }
  }

  String _fulfillmentTypeForDeliveryMode(DeliveryMode mode) {
    switch (mode) {
      case DeliveryMode.delivery:
        return 'delivery';
      case DeliveryMode.dineIn:
        return 'dine_in';
      case DeliveryMode.takeout:
        return 'takeout';
    }
  }

  void _setDeliveryMode(DeliveryMode mode) {
    if (_deliveryMode != mode) {
      setState(() => _deliveryMode = mode);
    }
    context.read<ServiceProvider>().setSelectedFulfillmentType(
      _fulfillmentTypeForDeliveryMode(mode),
    );
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

  Future<void> _loadRewardRedemptions() async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      setState(() {
        _activeRewardRedemptions = [];
        _selectedRewardRedemption = null;
        _isLoadingRewardRedemptions = false;
      });
      return;
    }

    setState(() => _isLoadingRewardRedemptions = true);
    final response = await serviceProvider.fetchRewardRedemptions();
    if (!mounted) return;

    final redemptions = (response?['redemptions'] as List? ?? [])
        .whereType<Map>()
        .map(
          (item) =>
              RewardRedemptionSummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .where(
          (item) =>
              item.id.isNotEmpty &&
              (item.discountAmount > 0 || item.isProductReward),
        )
        .toList(growable: false);
    final selectedId = _selectedRewardRedemption?.id ?? '';
    RewardRedemptionSummary? selected;
    for (final redemption in redemptions) {
      if (redemption.id == selectedId) {
        selected = redemption;
        break;
      }
    }

    setState(() {
      _activeRewardRedemptions = redemptions;
      _selectedRewardRedemption = selected;
      _isLoadingRewardRedemptions = false;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showRewardPicker() async {
    await _loadRewardRedemptions();
    if (!mounted) return;

    final selected = await showModalBottomSheet<RewardRedemptionSummary?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.of(sheetContext).padding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Reward',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_activeRewardRedemptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No active reward vouchers available.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _activeRewardRedemptions.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final redemption = _activeRewardRedemptions[index];
                        final isSelected =
                            redemption.id == _selectedRewardRedemption?.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(redemption.title),
                          subtitle: Text(
                            '${redemption.valueLabel} • ${redemption.expiresLabel}',
                          ),
                          trailing: Text('${redemption.pointsCost} pts'),
                          onTap: () => Navigator.pop(sheetContext, redemption),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, null),
                    child: const Text('No reward'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _selectedRewardRedemption = selected);
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

  String? get _orderNoteForRequest {
    final note = _orderNote.trim();
    return note.isEmpty ? null : note;
  }

  Future<void> _showOrderNoteSheet() async {
    _orderNoteController.text = _orderNote;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final primaryColor = Theme.of(sheetContext).colorScheme.primary;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Order Note',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add instructions for the whole order.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _orderNoteController,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Example: Please pack sauces separately.',
                    filled: true,
                    fillColor: primaryColor.withValues(alpha: 0.045),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _orderNote = '';
                          _orderNoteController.clear();
                        });
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Clear'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _orderNote = _orderNoteController.text.trim();
                        });
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Save Note'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateQuantity(String id, int delta) {
    context.read<ServiceProvider>().updateQuantity(id, delta);
  }

  Product2ItemData? _productForOrderItem(OrderItem item) {
    final serviceProvider = context.read<ServiceProvider>();
    final productData = serviceProvider.productDataForId(item.productId);
    if (productData == null) return null;

    return Product2ItemData.fromJson(
      productData,
      imageRoot: serviceProvider.fetchImageRoot(),
    );
  }

  String _cartItemIdForDetailOrder(
    Product2ItemData product,
    ProductDetailOrderData orderData,
  ) {
    final optionParts =
        orderData.selections.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) {
              final values = entry.value.toList()..sort();
              return '${entry.key}:${values.join(",")}';
            })
            .toList()
          ..sort();
    final optionsKey = optionParts.join('|');
    final specialInstructions = orderData.specialInstructions.trim();
    final specialInstructionsKey = specialInstructions.isEmpty
        ? ''
        : 'note:${Uri.encodeComponent(specialInstructions)}';
    final itemKeyParts = [
      if (optionsKey.isNotEmpty) optionsKey,
      if (specialInstructionsKey.isNotEmpty) specialInstructionsKey,
    ];

    return itemKeyParts.isEmpty
        ? product.id
        : '${product.id}|${itemKeyParts.join("|")}';
  }

  OrderItem _orderItemFromDetailOrder(
    Product2ItemData product,
    ProductDetailOrderData orderData,
  ) {
    final specialInstructions = orderData.specialInstructions.trim();

    return OrderItem(
      id: _cartItemIdForDetailOrder(product, orderData),
      productId: product.id,
      name: product.name,
      quantity: orderData.quantity,
      price: orderData.unitPrice,
      imagePath: product.imageUrl ?? 'assets/images/hamberger2.jpg',
      description: product.description,
      selectedOptions: orderData.selections,
      specialInstructions: specialInstructions,
    );
  }

  Future<void> _editOrderItem(OrderItem item) async {
    final product = _productForOrderItem(item);
    if (product == null) {
      _showSnackBar('This product is no longer available for editing.');
      return;
    }

    if (!product.isAvailable) {
      _showSnackBar('${product.name} is currently unavailable.');
      return;
    }

    final serviceProvider = context.read<ServiceProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (detailContext) => ProductDetail(
          id: product.id,
          name: product.name,
          description: product.description,
          storeName: _storeName,
          imageProvider: product.resolveImageProvider(),
          basePrice: product.basePrice,
          ratingAverage: product.ratingAverage,
          ratingCount: product.ratingCount,
          initialQuantity: item.quantity,
          initialSelections: item.selectedOptions,
          initialSpecialInstructions: item.specialInstructions,
          actionButtonLabel: 'Update item',
          optionGroups: product.optionGroups,
          onAddToOrder: (orderData) {
            final updatedItem = _orderItemFromDetailOrder(product, orderData);
            serviceProvider.replaceCartItem(item.id, updatedItem);
            Navigator.of(detailContext).pop();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated ${product.name} in your order.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  String _selectedOptionsLabel(OrderItem item) {
    final selectedOptions = item.selectedOptions;
    if (!selectedOptions.values.any((values) => values.isNotEmpty)) {
      return '';
    }

    final product = _productForOrderItem(item);
    if (product == null || product.optionGroups.isEmpty) {
      return selectedOptions.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value.join(", ")}')
          .join(' · ');
    }

    final labels = _selectedOptionLabelsFromGroups(
      product.optionGroups,
      selectedOptions,
    );
    if (labels.isNotEmpty) return labels.join(' · ');

    return selectedOptions.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value.join(", ")}')
        .join(' · ');
  }

  List<String> _selectedOptionLabelsFromGroups(
    List<ProductDetailOptionGroup> groups,
    Map<String, List<String>> selectedOptions,
  ) {
    final labels = <String>[];

    for (final group in groups) {
      final selectedIds = selectedOptions[group.id] ?? const <String>[];
      final optionLabels = <String>[];
      for (final selectedId in selectedIds) {
        final option = _findOptionById(group.options, selectedId);
        if (option == null) continue;
        optionLabels.add(_formatSelectedOption(option));
      }
      if (optionLabels.isNotEmpty) {
        labels.add('${group.title}: ${optionLabels.join(", ")}');
      }

      for (final option in group.options) {
        labels.addAll(
          _selectedOptionLabelsFromGroups(option.childGroups, selectedOptions),
        );
      }
    }

    return labels;
  }

  ProductDetailOption? _findOptionById(
    List<ProductDetailOption> options,
    String optionId,
  ) {
    for (final option in options) {
      if (option.id == optionId) return option;
    }
    return null;
  }

  String _formatSelectedOption(ProductDetailOption option) {
    if (option.extraPrice <= 0) return option.title;
    return '${option.title} (+CA\$${option.extraPrice.toStringAsFixed(2)})';
  }

  double get subtotal => context.read<ServiceProvider>().cartSubtotal;
  OrderPricingConfig get pricingConfig =>
      context.read<ServiceProvider>().orderPricingConfig;
  String get currencyCode => pricingConfig.currency;
  double get deliveryFee => pricingConfig.deliveryFee;
  double get deliveryServiceFee => pricingConfig.deliveryServiceFee;
  double get taxes => subtotal * pricingConfig.taxRate;

  String _formatMoney(double amount) {
    final prefix = amount < 0 ? '-' : '';
    return '$prefix$currencyCode \$${amount.abs().toStringAsFixed(2)}';
  }

  double get tipAmount {
    if (_tipPercentage == -1) {
      return _customTip;
    } else if (_tipPercentage > 0) {
      return subtotal * _tipPercentage;
    }
    return 0.0;
  }

  double get totalBeforeRewards {
    if (_deliveryMode == DeliveryMode.delivery) {
      return subtotal + deliveryFee + deliveryServiceFee + taxes + tipAmount;
    }
    return subtotal + taxes + tipAmount;
  }

  double get rewardDiscount {
    final selected = _selectedRewardRedemption;
    if (selected == null) return 0;
    if (selected.isProductReward) return 0;
    return selected.discountAmount.clamp(0, totalBeforeRewards).toDouble();
  }

  double get total => (totalBeforeRewards - rewardDiscount)
      .clamp(0, double.infinity)
      .toDouble();

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

  String get _tipExplanation {
    switch (_deliveryMode) {
      case DeliveryMode.delivery:
        return '100% goes to your delivery driver.';
      case DeliveryMode.dineIn:
        return '100% goes to the restaurant team serving your table.';
      case DeliveryMode.takeout:
        return '100% goes to the restaurant team preparing your pickup order.';
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

  BusinessHoursConfig get _businessHoursConfig =>
      context.read<ServiceProvider>().businessHoursConfig;
  PickupEtaConfig get _pickupEtaConfig =>
      context.read<ServiceProvider>().pickupEtaConfig;

  String get _businessHoursLabel =>
      _businessHoursConfig.hoursLabelFor(DateTime.now());

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

  String _formatDateTime(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  bool _isWithinBusinessHours(DateTime value) {
    return _businessHoursConfig.isOpenAt(value);
  }

  DateTime _firstSchedulableDateTime() {
    return _businessHoursConfig.firstSchedulableDateTime();
  }

  String? _scheduledDeliveryTimeError(DateTime? value) {
    if (value == null) return 'Please select a scheduled delivery time.';
    if (value.isBefore(DateTime.now())) {
      return 'Scheduled delivery time must be in the future.';
    }
    if (!_isWithinBusinessHours(value)) {
      final label = _businessHoursConfig.hoursLabelFor(value);
      return 'Scheduled delivery time must be within business hours ($label).';
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
        orderNote: _orderNoteForRequest,
        shippingAddressId: _shippingAddressIdForRequest,
        shippingAddress: _shippingAddressForRequest,
        rewardRedemptionId: _selectedRewardRedemption?.id,
        tipAmount: tipAmount,
      );

      if (!mounted) return;
      if (response != null) {
        setState(() {
          _orderNote = '';
          _orderNoteController.clear();
        });
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
            if (_showFishAlertWarning)
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
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.18),
                      ),
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
            if (_showSupplyChainShortageWarning) ...[
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
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.grey[600],
                      ),
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
            ],
            const SizedBox(height: 20),
            _buildRewardSection(),
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
                    _tipExplanation,
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
            const SizedBox(height: 12),
            _buildOrderNoteSection(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', _formatMoney(subtotal)),
                  if (_deliveryMode == DeliveryMode.delivery) ...[
                    _buildPriceRow('Delivery Fee', _formatMoney(deliveryFee)),
                    _buildPriceRow(
                      'Delivery Service Fee',
                      _formatMoney(deliveryServiceFee),
                    ),
                  ],
                  _buildPriceRow('Taxes', _formatMoney(taxes)),
                  _buildPriceRow('Tip', _formatMoney(tipAmount)),
                  if (rewardDiscount > 0)
                    _buildPriceRow(
                      'Reward Discount',
                      _formatMoney(-rewardDiscount),
                    ),
                  const Divider(height: 30, thickness: 1, color: Colors.grey),
                  _buildPriceRow('Total', _formatMoney(total), isTotal: true),
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
                : 'Make My Order • ${_formatMoney(total)}',
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

  Widget _buildRewardSection() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final selected = _selectedRewardRedemption;
    final hasRewards = _activeRewardRedemptions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.local_offer_outlined, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rewards',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (_isLoadingRewardRedemptions)
                    Text(
                      'Loading reward vouchers...',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  else if (selected != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selected.valueLabel} applied',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      hasRewards
                          ? 'Choose a voucher for this order.'
                          : 'No active reward vouchers available.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoadingRewardRedemptions
                      ? null
                      : _showRewardPicker,
                  child: Text(selected == null ? 'Choose' : 'Change'),
                ),
                if (selected != null)
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedRewardRedemption = null),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
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
        onPressed: () => _setDeliveryMode(mode),
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
                    _setDeliveryMode(DeliveryMode.dineIn);
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
              'Ready in ${_pickupEtaConfig.display}',
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isUnavailable = !item.isAvailable;
    final statusMessage = isUnavailable
        ? (item.availabilityMessage.isEmpty
              ? 'This item is no longer available.'
              : item.availabilityMessage)
        : item.priceChanged
        ? item.availabilityMessage
        : '';
    final selectedOptionsLabel = _selectedOptionsLabel(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnavailable
              ? Colors.red.shade200
              : primaryColor.withValues(alpha: 0.18),
          width: isUnavailable ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editOrderItem(item),
          borderRadius: BorderRadius.circular(8),
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Unit price: ${_formatMoney(item.price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.86),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (selectedOptionsLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            selectedOptionsLabel,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (item.specialInstructions.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Note: ${item.specialInstructions.trim()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _editOrderItem(item),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          TextButton(
                            onPressed: () =>
                                _updateQuantity(item.id, -item.quantity),
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
                        ],
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
                      : _formatMoney(item.quantity * item.price),
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

  Widget _buildOrderNoteSection() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasNote = _orderNote.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showOrderNoteSheet,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasNote ? 'Order Note' : 'Add Note',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasNote
                            ? _orderNote.trim()
                            : 'Add instructions for the whole order.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hasNote ? 'Edit' : 'Add',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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
                _formatMoney(amount),
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
                          hintText: '$currencyCode \$0.00',
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
                      _customTip > 0 ? _formatMoney(_customTip) : ' ',
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
