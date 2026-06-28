// E:/flutter_project/speedfeast/lib/Controller/service_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Common/service_config.dart';
import 'api_service.dart';
import '../Security/collect_features.dart';
import '../Common/order_item.dart';

class _SelectedOptionPriceResult {
  final double total;
  final bool hasMissingSelection;

  const _SelectedOptionPriceResult({
    required this.total,
    this.hasMissingSelection = false,
  });
}

class ServiceProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _guestCartStorageKey = 'speedfeast_cart_guest';
  static const String _userCartStoragePrefix = 'speedfeast_cart_user_';

  ServiceConfig? _config;
  dynamic _initData;
  bool _isLoggedIn = false;
  String? _userToken;
  String? _registrationToken;
  String? _lastOrderError;
  String? _lastPaymentError;
  String? _lastRecentOrdersError;
  String? _lastRewardsError;
  String? _lastReviewError;
  String? _lastDineInError;
  String? _lastLoginError;
  String _selectedFulfillmentType = 'delivery';
  Map<String, dynamic>? _dineInTableContext;
  late ApiService _apiService;

  bool get isLoggedIn => _isLoggedIn;
  dynamic get initData => _initData;
  ServiceConfig? get config => _config;
  String? get userToken => _userToken;
  String? get lastOrderError => _lastOrderError;
  String? get lastPaymentError => _lastPaymentError;
  String? get lastRecentOrdersError => _lastRecentOrdersError;
  String? get lastRewardsError => _lastRewardsError;
  String? get lastReviewError => _lastReviewError;
  String? get lastDineInError => _lastDineInError;
  String? get lastLoginError => _lastLoginError;
  String get selectedFulfillmentType => _selectedFulfillmentType;
  Map<String, dynamic>? get dineInTableContext => _dineInTableContext == null
      ? null
      : Map<String, dynamic>.from(_dineInTableContext!);
  bool get hasDineInTableContext => _dineInTableContext != null;
  String get dineInTableNumber =>
      _dineInTableContext?['table_number']?.toString() ?? '';
  String get dineInTableId =>
      _dineInTableContext?['table_id']?.toString() ?? '';
  String get dineInTableToken =>
      _dineInTableContext?['table_token']?.toString() ?? '';

  Map<String, String> features = {};
  bool _isInitialized = false;

  // --- Cart Management ---
  final List<OrderItem> _cartItems = [];
  String _activeCartStorageKey = _guestCartStorageKey;
  bool _hasLoadedCart = false;
  List<OrderItem> get cartItems => _cartItems;

  int get cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get cartSubtotal => _cartItems
      .where((item) => item.isAvailable)
      .fold(0.0, (sum, item) => sum + item.subtotal);

  bool get hasUnavailableCartItems =>
      _cartItems.any((item) => !item.isAvailable);

  List<OrderItem> get unavailableCartItems =>
      _cartItems.where((item) => !item.isAvailable).toList(growable: false);

  String _cartStorageKeyForToken(String? token) {
    final userId = _userIdFromToken(token);
    if (userId == null || userId.isEmpty) return _guestCartStorageKey;
    return '$_userCartStoragePrefix$userId';
  }

  String? _userIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadJson);
      if (payload is! Map) return null;

      final userId = payload['user_id'] ?? payload['userId'] ?? payload['sub'];
      final text = userId?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    } catch (e) {
      debugPrint('Unable to read user id from token for cart storage: $e');
      return null;
    }
  }

  Future<void> _loadCartForStorageKey(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawCart = prefs.getString(storageKey);
    final nextItems = <OrderItem>[];

    if (rawCart != null && rawCart.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCart);
        final rawItems = decoded is Map
            ? decoded['items']
            : decoded is List
            ? decoded
            : null;

        if (rawItems is List) {
          for (final rawItem in rawItems) {
            if (rawItem is! Map) continue;
            final item = OrderItem.fromJson(Map<String, dynamic>.from(rawItem));
            if (item.id.isEmpty || item.productId.isEmpty) continue;
            nextItems.add(item);
          }
        }
      } catch (e) {
        debugPrint('Unable to load cart from local storage: $e');
      }
    }

    _activeCartStorageKey = storageKey;
    _hasLoadedCart = true;
    _cartItems
      ..clear()
      ..addAll(nextItems);
    _refreshCartItemsFromProductData();
  }

  Future<void> _saveCartForStorageKey(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (_cartItems.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }

    await prefs.setString(
      storageKey,
      jsonEncode({
        'version': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'items': _cartItems.map((item) => item.toJson()).toList(),
      }),
    );
  }

  void _persistCartForActiveUser() {
    _saveCartForStorageKey(_activeCartStorageKey);
  }

  Future<void> _switchCartStorageForToken(String? token) async {
    if (_hasLoadedCart) {
      await _saveCartForStorageKey(_activeCartStorageKey);
    }
    await _loadCartForStorageKey(_cartStorageKeyForToken(token));
  }

  bool _refreshCartItemsFromProductData({bool persist = true}) {
    final productsById = _latestProductsById();
    if (productsById.isEmpty || _cartItems.isEmpty) return false;

    var changed = false;
    for (var index = 0; index < _cartItems.length; index += 1) {
      final item = _cartItems[index];
      final product = productsById[item.productId];
      final nextItem = product == null
          ? _markCartItemUnavailable(item)
          : _hydrateCartItemFromProduct(item, product);

      if (_cartItemChanged(item, nextItem)) {
        _cartItems[index] = nextItem;
        changed = true;
      }
    }

    if (changed && persist) {
      _persistCartForActiveUser();
    }
    return changed;
  }

  Map<String, Map<String, dynamic>> _latestProductsById() {
    final data = _initData;
    if (data == null) return const {};

    final productsById = <String, Map<String, dynamic>>{};
    void collect(dynamic value) {
      if (value is List) {
        for (final item in value) {
          collect(item);
        }
        return;
      }

      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final productId = _readProductText(map, ['product_id', 'productId']);
        if (productId.isNotEmpty) {
          productsById[productId] = map;
          return;
        }

        for (final child in map.values) {
          collect(child);
        }
      }
    }

    collect(data);
    return productsById;
  }

  OrderItem _markCartItemUnavailable(OrderItem item) {
    return item.copyWith(
      isAvailable: false,
      availabilityMessage: 'This item is no longer available.',
      priceChanged: false,
    );
  }

  OrderItem _hydrateCartItemFromProduct(
    OrderItem item,
    Map<String, dynamic> product,
  ) {
    final isActive = _isProductAvailable(product);
    if (!isActive) {
      return item.copyWith(
        isAvailable: false,
        availabilityMessage: 'This item is currently unavailable.',
        priceChanged: false,
      );
    }

    final nextName = _readProductText(product, [
      'product_name',
      'productName',
      'name',
    ]);
    final nextDescription = _readProductText(product, ['description']);
    final nextImagePath = _resolveProductImagePath(
      _readProductText(product, ['image_url', 'imageUrl', 'image_path']),
    );
    final basePrice = _readProductPrice(product);
    final optionPriceResult = _readSelectedOptionPriceDelta(
      product,
      item.selectedOptions,
    );

    if (optionPriceResult.hasMissingSelection) {
      return item.copyWith(
        isAvailable: false,
        availabilityMessage:
            'One or more selected options are no longer available.',
        priceChanged: false,
      );
    }

    final nextPrice = basePrice == null
        ? null
        : basePrice + optionPriceResult.total;
    final hasPrice = nextPrice != null;
    final priceChanged = hasPrice && (item.price - nextPrice).abs() >= 0.01;

    return item.copyWith(
      name: nextName.isNotEmpty ? nextName : item.name,
      price: hasPrice ? nextPrice : item.price,
      imagePath: nextImagePath.isNotEmpty ? nextImagePath : item.imagePath,
      description: nextDescription.isNotEmpty
          ? nextDescription
          : item.description,
      isAvailable: true,
      availabilityMessage: priceChanged
          ? 'Price updated from CAD \$${item.price.toStringAsFixed(2)} to CAD \$${nextPrice.toStringAsFixed(2)}.'
          : '',
      priceChanged: priceChanged,
    );
  }

  bool _cartItemChanged(OrderItem current, OrderItem next) {
    return current.name != next.name ||
        current.price != next.price ||
        current.imagePath != next.imagePath ||
        current.description != next.description ||
        current.isAvailable != next.isAvailable ||
        current.availabilityMessage != next.availabilityMessage ||
        current.priceChanged != next.priceChanged;
  }

  bool _isProductAvailable(Map<String, dynamic> product) {
    final status = _readProductText(product, [
      'status',
      'product_status',
    ]).toLowerCase();
    if (status.isEmpty) return true;
    return status == 'active' || status == 'available' || status == 'enabled';
  }

  String _readProductText(Map<String, dynamic> product, List<String> keys) {
    for (final key in keys) {
      final value = product[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  double? _readProductPrice(Map<String, dynamic> product) {
    for (final key in const [
      'base_price',
      'basePrice',
      'extra_price',
      'extraPrice',
      'price',
      'unit_price',
    ]) {
      final value = product[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  _SelectedOptionPriceResult _readSelectedOptionPriceDelta(
    Map<String, dynamic> product,
    Map<String, List<String>> selectedOptions,
  ) {
    final normalizedOptions = _selectedOptionsForRequest(selectedOptions);
    if (normalizedOptions.isEmpty) {
      return const _SelectedOptionPriceResult(total: 0);
    }

    final seenGroupIds = <String>{};
    final result = _readOptionGroupsPrice(
      product['option_groups'] ?? product['optionGroups'],
      normalizedOptions,
      seenGroupIds,
    );
    final hasMissingGroup = normalizedOptions.keys.any(
      (groupId) => !seenGroupIds.contains(groupId),
    );

    return _SelectedOptionPriceResult(
      total: result.total,
      hasMissingSelection: result.hasMissingSelection || hasMissingGroup,
    );
  }

  _SelectedOptionPriceResult _readOptionGroupsPrice(
    dynamic rawGroups,
    Map<String, List<String>> selectedOptions,
    Set<String> seenGroupIds,
  ) {
    if (rawGroups is! List) {
      return const _SelectedOptionPriceResult(total: 0);
    }

    var total = 0.0;
    var hasMissingSelection = false;

    for (final rawGroup in rawGroups) {
      if (rawGroup is! Map) continue;
      final group = Map<String, dynamic>.from(rawGroup);
      final groupId = _readProductText(group, [
        'id',
        'option_group_id',
        'group_id',
      ]);
      final selectedIds = selectedOptions[groupId] ?? const <String>[];

      if (groupId.isNotEmpty && selectedOptions.containsKey(groupId)) {
        seenGroupIds.add(groupId);
      }
      if (selectedIds.isEmpty) continue;

      final rawOptions = group['options'];
      if (rawOptions is! List) {
        hasMissingSelection = true;
        continue;
      }

      final optionsById = <String, Map<String, dynamic>>{};
      for (final rawOption in rawOptions) {
        if (rawOption is! Map) continue;
        final option = Map<String, dynamic>.from(rawOption);
        final optionId = _readProductText(option, [
          'id',
          'option_product_id',
          'product_id',
        ]);
        if (optionId.isNotEmpty) {
          optionsById[optionId] = option;
        }
      }

      for (final selectedId in selectedIds) {
        final option = optionsById[selectedId];
        if (option == null) {
          hasMissingSelection = true;
          continue;
        }

        total += _readProductPrice(option) ?? 0;
        final childResult = _readOptionGroupsPrice(
          option['child_groups'] ?? option['childGroups'],
          selectedOptions,
          seenGroupIds,
        );
        total += childResult.total;
        hasMissingSelection =
            hasMissingSelection || childResult.hasMissingSelection;
      }
    }

    return _SelectedOptionPriceResult(
      total: total,
      hasMissingSelection: hasMissingSelection,
    );
  }

  String _resolveProductImagePath(String imagePath) {
    if (imagePath.isEmpty ||
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('assets/')) {
      return imagePath;
    }
    return '${fetchImageRoot()}$imagePath';
  }

  Map<String, List<String>> _selectedOptionsForRequest(
    Map<String, List<String>> selectedOptions,
  ) {
    final normalized = <String, List<String>>{};

    for (final entry in selectedOptions.entries) {
      final groupId = entry.key.trim();
      if (groupId.isEmpty) continue;

      final optionIds = <String>[];
      for (final rawOptionId in entry.value) {
        final optionId = rawOptionId.trim();
        if (optionId.isEmpty || optionIds.contains(optionId)) continue;
        optionIds.add(optionId);
      }

      if (optionIds.isNotEmpty) {
        normalized[groupId] = optionIds;
      }
    }

    return normalized;
  }

  void addToCart(OrderItem item) {
    final index = _cartItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _cartItems[index].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    _persistCartForActiveUser();
    notifyListeners();
  }

  void setCartItemQuantity(OrderItem item, int quantity) {
    final index = _cartItems.indexWhere((i) => i.id == item.id);
    if (quantity <= 0) {
      if (index != -1) {
        _cartItems.removeAt(index);
        _persistCartForActiveUser();
        notifyListeners();
      }
      return;
    }

    if (index != -1) {
      _cartItems[index].quantity = quantity;
    } else {
      item.quantity = quantity;
      _cartItems.add(item);
    }
    _persistCartForActiveUser();
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index].quantity += delta;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
      _persistCartForActiveUser();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _persistCartForActiveUser();
    notifyListeners();
  }

  void clearDineInTableContext() {
    _dineInTableContext = null;
    _lastDineInError = null;
    notifyListeners();
  }

  void setSelectedFulfillmentType(String fulfillmentType) {
    final normalized = fulfillmentType.trim().toLowerCase().replaceAll(
      '-',
      '_',
    );
    final nextType = switch (normalized) {
      'dine_in' => 'dine_in',
      'takeout' || 'take_out' => 'takeout',
      _ => 'delivery',
    };

    if (_selectedFulfillmentType == nextType) return;
    _selectedFulfillmentType = nextType;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> verifyDineInTable(String qrCode) async {
    final rawCode = qrCode.trim();
    if (_config == null) {
      _lastDineInError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for verifyDineInTable.');
      return null;
    }
    if (rawCode.isEmpty) {
      _lastDineInError = 'Please scan or enter a table code.';
      return null;
    }

    try {
      _lastDineInError = null;
      final rawResponse = await _apiService.post(
        _config!.getVerifyDineInTablePath(),
        <String, dynamic>{'qr_code': rawCode},
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) {
          final tableValue = responseData['table'];
          final table = tableValue is Map
              ? _asStringKeyedMap(tableValue)
              : <String, dynamic>{
                  'table_id': responseData['table_id'],
                  'store_id': responseData['store_id'],
                  'table_number': responseData['table_number'],
                  'table_token': responseData['table_token'],
                };

          final tableNumber = table['table_number']?.toString().trim() ?? '';
          if (tableNumber.isEmpty) {
            _lastDineInError = 'The table code response is missing a table.';
            return null;
          }

          _dineInTableContext = table;
          _selectedFulfillmentType = 'dine_in';
          notifyListeners();
          return table;
        }

        _lastDineInError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Table code could not be verified.';
        return null;
      }

      _lastDineInError = 'Unexpected response while verifying table code.';
      return null;
    } on AppException catch (e) {
      _lastDineInError = e.message;
      debugPrint('Error verifying dine-in table: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      _lastDineInError = 'Failed to verify table code.';
      debugPrint('An unexpected error occurred while verifying table: $e');
      debugPrint('Verify dine-in table stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createOrder({
    required String fulfillmentType,
    String? tableNumber,
    String? dineInTableId,
    String? tableToken,
    String? pickupLocation,
    String? deliveryNote,
    Map<String, dynamic>? shippingAddress,
    String? shippingAddressId,
    String? paymentMethodId,
    String? rewardRedemptionId,
    double tipAmount = 0,
  }) async {
    if (_config == null) {
      _lastOrderError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for createOrder.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastOrderError = 'Please log in before making an order.';
      debugPrint('Cannot create order: user token is missing.');
      return null;
    }
    if (_cartItems.isEmpty) {
      _lastOrderError = 'Please add at least one item.';
      debugPrint('Cannot create order: cart is empty.');
      return null;
    }
    OrderItem? unavailableItem;
    for (final item in _cartItems) {
      if (!item.isAvailable) {
        unavailableItem = item;
        break;
      }
    }
    if (unavailableItem != null) {
      _lastOrderError =
          'Cart item "${unavailableItem.name}" is no longer available. Please remove it before ordering.';
      debugPrint(_lastOrderError);
      return null;
    }

    final normalizedFulfillmentType = fulfillmentType == 'dine-in'
        ? 'dine_in'
        : fulfillmentType;
    OrderItem? invalidItem;
    for (final item in _cartItems) {
      final productId = item.productId.trim();
      if (productId.isEmpty || productId.toLowerCase() == 'null') {
        invalidItem = item;
        break;
      }
    }
    if (invalidItem != null) {
      _lastOrderError =
          'Cart item "${invalidItem.name}" has an invalid product id.';
      debugPrint(
        'Cannot create order: cart item "${invalidItem.name}" has an invalid product id.',
      );
      return null;
    }

    final requestBody = <String, dynamic>{
      'currency': 'CAD',
      'fulfillment_type': normalizedFulfillmentType,
      'tip_amount': tipAmount,
      'items': _cartItems.map((item) {
        final selectedOptions = _selectedOptionsForRequest(
          item.selectedOptions,
        );
        final specialInstructions = item.specialInstructions.trim();
        return {
          'product_id': item.productId,
          'quantity': item.quantity,
          if (selectedOptions.isNotEmpty) 'selected_options': selectedOptions,
          if (specialInstructions.isNotEmpty)
            'special_instructions': specialInstructions,
        };
      }).toList(),
      if (shippingAddressId != null && shippingAddressId.isNotEmpty)
        'shipping_address_id': shippingAddressId,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (paymentMethodId != null && paymentMethodId.isNotEmpty)
        'payment_method_id': paymentMethodId,
      if (rewardRedemptionId != null && rewardRedemptionId.isNotEmpty)
        'reward_redemption_id': rewardRedemptionId,
      if (tableNumber != null && tableNumber.isNotEmpty)
        'table_number': tableNumber,
      if (dineInTableId != null && dineInTableId.isNotEmpty)
        'dine_in_table_id': dineInTableId,
      if (tableToken != null && tableToken.isNotEmpty)
        'table_token': tableToken,
      if (pickupLocation != null && pickupLocation.isNotEmpty)
        'pickup_location': pickupLocation,
      if (deliveryNote != null && deliveryNote.isNotEmpty)
        'delivery_note': deliveryNote,
    };

    try {
      _lastOrderError = null;
      final rawResponse = await _apiService.post(
        _config!.getCreateOrderPath(),
        requestBody,
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        clearCart();
        debugPrint('Order created successfully: ${responseData['order']}');
        return responseData;
      }

      final errorMessage =
          responseData['error']?.toString() ?? 'Server indicated order failed.';
      _lastOrderError = errorMessage;
      debugPrint('Server indicated order failure: $errorMessage');
      return null;
    } on AppException catch (e) {
      _lastOrderError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error creating order: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('An unexpected error occurred while creating order: $e');
      debugPrint('Create order stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createPayment({
    required String orderId,
    String provider = 'stripe',
  }) async {
    final normalizedOrderId = orderId.trim();
    if (_config == null) {
      _lastPaymentError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for createPayment.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastPaymentError = 'Please log in before paying for an order.';
      debugPrint('Cannot create payment: user token is missing.');
      return null;
    }
    if (normalizedOrderId.isEmpty) {
      _lastPaymentError = 'Order id is missing.';
      debugPrint('Cannot create payment: order id is missing.');
      return null;
    }

    try {
      _lastPaymentError = null;
      debugPrint(
        'Creating payment: ${_config!.getBaseUrl()}${_config!.getCreatePaymentPath()}',
      );
      final rawResponse = await _apiService.post(
        _config!.getCreatePaymentPath(),
        <String, dynamic>{'order_id': normalizedOrderId, 'provider': provider},
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return responseData;

        _lastPaymentError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated payment could not be created.';
        debugPrint('Server indicated payment failure: $_lastPaymentError');
        return null;
      }

      _lastPaymentError = 'Unexpected response while creating payment.';
      return null;
    } on AppException catch (e) {
      _lastPaymentError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error creating payment: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastPaymentError = 'Failed to create payment.';
      debugPrint('An unexpected error occurred while creating payment: $e');
      debugPrint('Create payment stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentOrders({int limit = 20}) async {
    if (_config == null) {
      _lastRecentOrdersError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for fetchRecentOrders.');
      return [];
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastRecentOrdersError = 'Please log in to view recent orders.';
      debugPrint('Cannot fetch recent orders: user token is missing.');
      return [];
    }

    try {
      _lastRecentOrdersError = null;
      debugPrint(
        'Fetching recent orders: ${_config!.getBaseUrl()}${_config!.getRecentOrdersPath()}',
      );
      final rawResponse = await _apiService.get(
        _config!.getRecentOrdersPath(),
        queryParameters: limit > 0 ? <String, dynamic>{'limit': limit} : null,
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == false) {
          _lastRecentOrdersError =
              responseData['error']?.toString() ??
              responseData['message']?.toString() ??
              'Server indicated recent orders could not be loaded.';
          debugPrint(
            'Server indicated recent orders failure: $_lastRecentOrdersError',
          );
          return [];
        }
      }

      final orders = _extractOrderMaps(rawResponse);
      return limit > 0 ? orders.take(limit).toList() : orders;
    } on AppException catch (e) {
      _lastRecentOrdersError = _recentOrdersErrorMessage(e);
      debugPrint('Error fetching recent orders: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return [];
    } catch (e, stackTrace) {
      _lastRecentOrdersError = 'Failed to load recent orders.';
      debugPrint('An unexpected error occurred while fetching orders: $e');
      debugPrint('Fetch recent orders stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchRewardsSummary() async {
    if (_config == null) {
      _lastRewardsError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for fetchRewardsSummary.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastRewardsError = 'Please log in to view rewards.';
      debugPrint('Cannot fetch rewards summary: user token is missing.');
      return null;
    }

    try {
      _lastRewardsError = null;
      debugPrint(
        'Fetching rewards summary: ${_config!.getBaseUrl()}${_config!.getRewardsSummaryPath()}',
      );
      final rawResponse = await _apiService.get(
        _config!.getRewardsSummaryPath(),
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return responseData;

        _lastRewardsError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated rewards could not be loaded.';
        debugPrint('Server indicated rewards failure: $_lastRewardsError');
        return null;
      }

      _lastRewardsError = 'Unexpected response while loading rewards.';
      return null;
    } on AppException catch (e) {
      _lastRewardsError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error fetching rewards summary: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastRewardsError = 'Failed to load rewards.';
      debugPrint('An unexpected error occurred while fetching rewards: $e');
      debugPrint('Fetch rewards stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchRewardsTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_config == null) {
      _lastRewardsError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for fetchRewardsTransactions.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastRewardsError = 'Please log in to view rewards.';
      debugPrint('Cannot fetch rewards transactions: user token is missing.');
      return null;
    }

    try {
      _lastRewardsError = null;
      debugPrint(
        'Fetching rewards transactions: ${_config!.getBaseUrl()}${_config!.getRewardsTransactionsPath()}',
      );
      final rawResponse = await _apiService.get(
        _config!.getRewardsTransactionsPath(),
        queryParameters: <String, dynamic>{'limit': limit, 'offset': offset},
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return responseData;

        _lastRewardsError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated rewards activity could not be loaded.';
        debugPrint(
          'Server indicated rewards transactions failure: $_lastRewardsError',
        );
        return null;
      }

      _lastRewardsError = 'Unexpected response while loading rewards activity.';
      return null;
    } on AppException catch (e) {
      _lastRewardsError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error fetching rewards transactions: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastRewardsError = 'Failed to load rewards activity.';
      debugPrint(
        'An unexpected error occurred while fetching rewards transactions: $e',
      );
      debugPrint('Fetch rewards transactions stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchRewardRedemptions({
    String status = 'active',
  }) async {
    if (_config == null) {
      _lastRewardsError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for fetchRewardRedemptions.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastRewardsError = 'Please log in to view rewards.';
      debugPrint('Cannot fetch reward redemptions: user token is missing.');
      return null;
    }

    try {
      _lastRewardsError = null;
      final queryParameters = <String, dynamic>{};
      if (status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }
      final rawResponse = await _apiService.get(
        _config!.getRewardsRedemptionsPath(),
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return responseData;

        _lastRewardsError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated reward vouchers could not be loaded.';
        debugPrint(
          'Server indicated reward redemptions failure: $_lastRewardsError',
        );
        return null;
      }

      _lastRewardsError = 'Unexpected response while loading reward vouchers.';
      return null;
    } on AppException catch (e) {
      _lastRewardsError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error fetching reward redemptions: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastRewardsError = 'Failed to load reward vouchers.';
      debugPrint(
        'An unexpected error occurred while fetching reward redemptions: $e',
      );
      debugPrint('Fetch reward redemptions stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> redeemReward(String rewardId) async {
    final normalizedRewardId = rewardId.trim();
    if (_config == null) {
      _lastRewardsError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for redeemReward.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastRewardsError = 'Please log in to redeem rewards.';
      debugPrint('Cannot redeem reward: user token is missing.');
      return null;
    }
    if (normalizedRewardId.isEmpty) {
      _lastRewardsError = 'Reward id is missing.';
      debugPrint('Cannot redeem reward: reward id is missing.');
      return null;
    }

    try {
      _lastRewardsError = null;
      final rawResponse = await _apiService.post(
        _config!.getRewardsRedeemPath(),
        <String, dynamic>{'reward_id': normalizedRewardId},
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) {
          notifyListeners();
          return responseData;
        }

        _lastRewardsError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated this reward could not be redeemed.';
        debugPrint(
          'Server indicated reward redeem failure: $_lastRewardsError',
        );
        return null;
      }

      _lastRewardsError = 'Unexpected response while redeeming reward.';
      return null;
    } on AppException catch (e) {
      _lastRewardsError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error redeeming reward: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastRewardsError = 'Failed to redeem reward.';
      debugPrint('An unexpected error occurred while redeeming reward: $e');
      debugPrint('Redeem reward stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (_config == null) {
      _lastRecentOrdersError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for cancelOrder.');
      return false;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastRecentOrdersError = 'Please log in to cancel an order.';
      debugPrint('Cannot cancel order: user token is missing.');
      return false;
    }
    if (normalizedOrderId.isEmpty) {
      _lastRecentOrdersError = 'Order id is missing.';
      debugPrint('Cannot cancel order: order id is missing.');
      return false;
    }

    try {
      _lastRecentOrdersError = null;
      debugPrint(
        'Cancelling order: ${_config!.getBaseUrl()}${_config!.getCancelOrderPath()}',
      );
      final rawResponse = await _apiService.post(
        _config!.getCancelOrderPath(),
        <String, dynamic>{'order_id': normalizedOrderId},
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return true;

        _lastRecentOrdersError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated the order could not be cancelled.';
        debugPrint(
          'Server indicated order cancellation failure: $_lastRecentOrdersError',
        );
        return false;
      }

      _lastRecentOrdersError = 'Unexpected response while cancelling order.';
      return false;
    } on AppException catch (e) {
      _lastRecentOrdersError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error cancelling order: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return false;
    } catch (e, stackTrace) {
      _lastRecentOrdersError = 'Failed to cancel order.';
      debugPrint('An unexpected error occurred while cancelling order: $e');
      debugPrint('Cancel order stack trace: $stackTrace');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchOrderReview(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (_config == null) {
      _lastReviewError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for fetchOrderReview.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastReviewError = 'Please log in to review an order.';
      debugPrint('Cannot fetch order review: user token is missing.');
      return null;
    }
    if (normalizedOrderId.isEmpty) {
      _lastReviewError = 'Order id is missing.';
      debugPrint('Cannot fetch order review: order id is missing.');
      return null;
    }

    try {
      _lastReviewError = null;
      final rawResponse = await _apiService.get(
        _config!.getOrderReviewPath(normalizedOrderId),
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return responseData;

        _lastReviewError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated the review could not be loaded.';
        return null;
      }

      _lastReviewError = 'Unexpected response while loading review.';
      return null;
    } on AppException catch (e) {
      _lastReviewError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error fetching order review: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastReviewError = 'Failed to load review.';
      debugPrint('An unexpected error occurred while fetching review: $e');
      debugPrint('Fetch review stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveOrderReview({
    required String orderId,
    required String comment,
    required List<Map<String, dynamic>> items,
  }) async {
    final normalizedOrderId = orderId.trim();
    if (_config == null) {
      _lastReviewError = 'Service config is not loaded.';
      debugPrint('Config not loaded yet for saveOrderReview.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _lastReviewError = 'Please log in to review an order.';
      debugPrint('Cannot save order review: user token is missing.');
      return null;
    }
    if (normalizedOrderId.isEmpty) {
      _lastReviewError = 'Order id is missing.';
      debugPrint('Cannot save order review: order id is missing.');
      return null;
    }
    if (items.isEmpty) {
      _lastReviewError = 'Please rate at least one item.';
      return null;
    }

    try {
      _lastReviewError = null;
      final rawResponse = await _apiService.post(
        _config!.getOrderReviewPath(normalizedOrderId),
        <String, dynamic>{'comment': comment.trim(), 'items': items},
        token: _userToken,
      );

      if (rawResponse is Map) {
        final responseData = _asStringKeyedMap(rawResponse);
        if (responseData['success'] == true) return responseData;

        _lastReviewError =
            responseData['error']?.toString() ??
            responseData['message']?.toString() ??
            'Server indicated the review could not be saved.';
        return null;
      }

      _lastReviewError = 'Unexpected response while saving review.';
      return null;
    } on AppException catch (e) {
      _lastReviewError = e.statusCode == 401
          ? 'Login expired. Please log in again.'
          : e.message;
      debugPrint('Error saving order review: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      _lastReviewError = 'Failed to save review.';
      debugPrint('An unexpected error occurred while saving review: $e');
      debugPrint('Save review stack trace: $stackTrace');
      return null;
    }
  }

  String _recentOrdersErrorMessage(AppException error) {
    if (error.statusCode == 401) {
      return 'Login expired. Please log in again.';
    }
    if (error.statusCode == 404 || _looksLikeHtmlNotFound(error.message)) {
      final path = _config?.getRecentOrdersPath() ?? 'listRecentOrders';
      return 'Recent orders API was not found at "$path". Please update listRecentOrders in assets/configs/web.json to match the backend order-history endpoint.';
    }
    return error.message;
  }

  bool _looksLikeHtmlNotFound(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('<!doctype html') &&
        normalized.contains('not found');
  }

  Map<String, dynamic> _asStringKeyedMap(Map value) {
    return value.map<String, dynamic>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  List<Map<String, dynamic>> _extractOrderMaps(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(_asStringKeyedMap)
          .toList(growable: false);
    }

    if (value is Map) {
      final data = _asStringKeyedMap(value);
      for (final key in const [
        'orders',
        'recent_orders',
        'recentOrders',
        'order_list',
        'orderList',
        'data',
        'items',
        'results',
      ]) {
        final candidate = data[key];
        final orders = _extractOrderMaps(candidate);
        if (orders.isNotEmpty) return orders;
      }

      final hasOrderShape =
          data.containsKey('order_id') ||
          data.containsKey('orderId') ||
          data.containsKey('order_no') ||
          data.containsKey('id');
      if (hasOrderShape) {
        return [data];
      }
    }

    return [];
  }

  ServiceProvider();

  // ** 4. 新增异步初始化方法 **
  Future<void> initialize() async {
    if (_isInitialized) return; // 防止重复初始化

    debugPrint('ServiceProvider initialization started.');

    // 调用 collectFeatures() 并等待结果
    features = await collectFeatures();
    debugPrint('Security features collected: $features');

    // 读取本地 token，但先不要把它视为已登录；必须等服务端验证通过。
    await _loadUserStatus(trustStoredToken: false, notify: false);

    // 加载配置 (此方法内部有 await)
    await loadConfig();

    if (_userToken != null && _userToken!.isNotEmpty) {
      final tokenIsValid = await validateToken();
      debugPrint(
        'Stored token validation during initialization: $tokenIsValid',
      );
    }

    // 初始化完成后，可以尝试获取初始化数据
    await fetchInitData();

    _isInitialized = true;
    notifyListeners();
    debugPrint('ServiceProvider initialization finished.');
  }

  // --- 用户状态管理 ---
  Future<void> _loadUserStatus({
    bool trustStoredToken = true,
    bool notify = true,
  }) async {
    _userToken = await _secureStorage.read(key: 'user_token');
    final hasStoredToken = _userToken != null && _userToken!.isNotEmpty;
    _isLoggedIn = trustStoredToken && hasStoredToken;
    await _switchCartStorageForToken(_userToken);
    debugPrint(
      'User status loaded: isLoggedIn=$_isLoggedIn, token=${hasStoredToken ? "exists" : "null"}',
    );
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> saveUserToken(String token) async {
    _registrationToken = null;
    await _switchCartStorageForToken(token);
    await _secureStorage.write(key: 'user_token', value: token);
    _userToken = token;
    _isLoggedIn = true;
    notifyListeners();
    debugPrint('User logged in. Token stored securely.');
    await fetchInitData();
  }

  Future<void> _clearUserSessionAndLoadGuestCart() async {
    _registrationToken = null;
    await _switchCartStorageForToken(null);
    await _secureStorage.delete(key: 'user_token');
    _userToken = null;
    _isLoggedIn = false;
  }

  void saveRegistrationToken(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) return;
    _registrationToken = normalizedToken;
    debugPrint('Registration token stored for current registration flow.');
  }

  Future<bool> loginUser({
    String? username,
    String? cellPhone,
    required String password,
  }) async {
    if (_config == null) {
      debugPrint('Config not loaded yet for loginUser.');
      _lastLoginError = 'Service config is not loaded.';
      return false;
    }
    if ((username == null || username.isEmpty) &&
        (cellPhone == null || cellPhone.isEmpty)) {
      debugPrint('Login failed: username or cell phone is required.');
      _lastLoginError = 'Phone number is required.';
      return false;
    }

    final Map<String, dynamic> requestBody = {
      'password': password,
      if (username != null && username.isNotEmpty) 'username': username,
      if (cellPhone != null && cellPhone.isNotEmpty) 'cell_phone': cellPhone,
    };

    try {
      _lastLoginError = null;
      _registrationToken = null;
      final rawResponse = await _apiService.post(
        _config!.getLoginPath(),
        requestBody,
      );
      final Map<String, dynamic> responseData =
          rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final token = responseData['token']?.toString();
        if (token == null || token.isEmpty) {
          debugPrint('Login failed: server did not return a token.');
          _lastLoginError = 'The server did not return a login token.';
          return false;
        }

        await saveUserToken(token);
        _lastLoginError = null;
        debugPrint('Login successful: ${responseData['message']}');
        return true;
      }

      final errorMessage =
          responseData['error']?.toString() ??
          responseData['message']?.toString() ??
          'Server indicated login failed.';
      _lastLoginError = errorMessage;
      debugPrint('Server indicated login failure: $errorMessage');
      return false;
    } on AppException catch (e) {
      debugPrint('Error during user login: ${e.message}');
      _lastLoginError = e.statusCode == 401
          ? 'Incorrect phone number or password.'
          : e.message;
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred during user login: $e');
      _lastLoginError = 'An unexpected error occurred during login.';
      return false;
    }
  }

  Future<bool> validateToken() async {
    if (_config == null) {
      debugPrint('Config not loaded yet for validateToken.');
      return false;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      await _clearUserSessionAndLoadGuestCart();
      notifyListeners();
      debugPrint('Token validation skipped: no token found.');
      return false;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.getValidatePath(),
        <String, dynamic>{},
        token: _userToken,
      );
      final Map<String, dynamic> responseData =
          rawResponse as Map<String, dynamic>;

      final bool isValid = responseData['success'] == true;
      _isLoggedIn = isValid;
      if (!isValid) {
        await _clearUserSessionAndLoadGuestCart();
      }
      notifyListeners();
      debugPrint('Token validation result: $isValid');
      return isValid;
    } on AppException catch (e) {
      debugPrint('Error validating token: ${e.message}');
      if (e.statusCode == 400 || e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred while validating token: $e');
      return false;
    }
  }

  Future<void> logoutUser() async {
    await _clearUserSessionAndLoadGuestCart();
    notifyListeners();
    debugPrint('User logged out. Token removed from secure storage.');
    _initData = null;
    await fetchInitData();
  }

  // --- 配置加载 ---
  Future<void> loadConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/configs/web.json');
      final jsonMap = jsonDecode(jsonString);
      _config = ServiceConfig.fromJson(jsonMap['service']);
      _apiService = ApiService(_config!.getBaseUrl());
      notifyListeners();
      debugPrint('ServiceConfig loaded: ${_config!.getBaseUrl()}');
    } catch (e) {
      debugPrint('Error loading config: $e');
      rethrow;
    }
  }

  // --- 数据获取方法 ---
  Future<void> fetchInitData() async {
    if (_config == null) {
      debugPrint('Config not loaded yet for fetchInitData.');
      throw AppException("Service configuration not loaded.");
    }
    try {
      final responseData = await _apiService.get(
        _config!.getProductListPath(),
        token: _userToken,
      );
      _initData = responseData;
      _refreshCartItemsFromProductData();
      notifyListeners();
      //debugPrint('Initial data fetched: $_initData');
    } on AppException catch (e) {
      debugPrint('Error fetching init data: ${e.message}');
    } catch (e) {
      debugPrint('An unexpected error occurred while fetching init data: $e');
    }
  }

  // 修改 sendVerificationCode 返回 Future<bool>
  Future<bool> sendVerificationCode(String emailOrPhone, String type) async {
    if (_config == null) {
      debugPrint('Config not loaded yet for sendVerificationCode.');
      return false;
    }
    final Map<String, dynamic> queryParameters = {
      'type': type,
      'target': emailOrPhone,
    }; // Construct a Map
    try {
      final rawResponse = await _apiService.get(
        _config!.getVerificationCodePath(),
        queryParameters: queryParameters, // Use the new argument name and Map
        token: _userToken,
      );
      // 解析响应体，检查 'success' 字段
      final Map<String, dynamic> responseData =
          rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint(
          'Verification code sent successfully: ${responseData['message']}',
        );
        return true; // 服务器指示成功
      } else {
        // 即使 HTTP 状态码是 200，但服务器业务逻辑指示失败
        String errorMessage =
            responseData['message']?.toString() ??
            'Server indicated failure to send verification code.';
        debugPrint('Server indicated failure: $errorMessage');
        return false;
      }
    } on AppException catch (e) {
      debugPrint('Error sending verification code: ${e.message}');
      return false; // 捕获到应用异常，返回 false
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while sending verification code: $e',
      );
      return false; // 捕获到其他未知异常，返回 false
    }
  }

  // 修改 verifyVerificationCode 返回 Future<bool> (同样遵循 success 字段)
  Future<bool> verifyVerificationCode(
    String emailOrPhone,
    String code,
    String type, {
    Map<String, dynamic>? resData,
  }) async {
    if (_config == null) {
      debugPrint('Config not loaded yet for verifyVerificationCode.');
      return false;
    }
    final Map<String, dynamic> queryParameters = {
      'type': type,
      'target': emailOrPhone,
      'code': code,
    }; // Construct a Map
    try {
      final rawResponse = await _apiService.get(
        _config!.verifyVerificationCodePath(),
        queryParameters: queryParameters, // Use the new argument name and Map
        token: _userToken,
      );
      // 解析响应体，检查 'success' 字段
      final Map<String, dynamic> responseData =
          rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('Verification successful: ${responseData['message']}');
        resData?.addAll(responseData);
        return true; // 服务器指示成功
      } else {
        // 即使 HTTP 状态码是 200，但服务器业务逻辑指示失败
        String errorMessage =
            responseData['message']?.toString() ??
            'Server indicated verification failed.';
        debugPrint('Server indicated failure: $errorMessage');
        return false;
      }
    } on AppException catch (e) {
      debugPrint('Error verifying verification code: ${e.message}');
      return false;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while verifying verification code: $e',
      );
      return false;
    }
  }

  // 新增：提交注册信息功能
  Future<bool> registerUser(
    String username,
    String phone,
    String email,
    String password,
  ) async {
    if (_config == null) {
      debugPrint('Config not loaded yet for registerUser.');
      return false;
    }

    final Map<String, dynamic> requestBody = {
      'username': username,
      'cell_phone': phone,
      'email': email,
      'password': password,
      // 如果后端需要确认密码，可以添加 'confirmPassword': password
    };
    final tokenForRegistration = _registrationToken ?? _userToken;
    if (tokenForRegistration == null || tokenForRegistration.isEmpty) {
      debugPrint('Cannot register user: registration token is missing.');
      return false;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.getRegisterPath(), // 使用新的注册接口路径
        requestBody, // 将请求体传递给post方法
        token: tokenForRegistration,
      );

      final Map<String, dynamic> responseData =
          rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('Registration successful: ${responseData['message']}');
        final token = responseData['token']?.toString();
        if (token == null || token.isEmpty) {
          debugPrint(
            'Registration failed: server did not return a login token.',
          );
          return false;
        }

        await saveUserToken(token);
        return true;
      } else {
        String errorMessage =
            responseData['message']?.toString() ??
            'Server indicated registration failed.';
        debugPrint(
          'Server indicated failure during registration: $errorMessage',
        );
        return false;
      }
    } on AppException catch (e) {
      debugPrint('Error during user registration: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred during user registration: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchPersonalInfo() async {
    if (_config == null) {
      debugPrint('Config not loaded yet for fetchPersonalInfo.');
      return null;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot fetch personal info: user token is missing.');
      return null;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.getPersonalInfoPath(),
        <String, dynamic>{},
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true ? responseData : null;
    } on AppException catch (e) {
      debugPrint('Error fetching personal info: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while fetching personal info: $e',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String cellPhone,
    String? originalPassword,
    String? newPassword,
    String? confirmPassword,
  }) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot update personal info: config or token is missing.');
      return null;
    }

    final requestBody = <String, dynamic>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'username': [
        firstName.trim(),
        lastName.trim(),
      ].where((value) => value.isNotEmpty).join(' '),
      'email': email.trim(),
      'phone_number': cellPhone.trim(),
      'cell_phone': cellPhone.trim(),
      if (originalPassword != null && originalPassword.isNotEmpty)
        'original_password': originalPassword,
      if (newPassword != null && newPassword.isNotEmpty)
        'new_password': newPassword,
      if (confirmPassword != null && confirmPassword.isNotEmpty)
        'confirm_password': confirmPassword,
    };

    try {
      final rawResponse = await _apiService.post(
        _config!.updatePersonalInfoPath(),
        requestBody,
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true ? responseData : null;
    } on AppException catch (e) {
      debugPrint('Error updating personal info: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return null;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while updating personal info: $e',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> createAddress(
    Map<String, dynamic> address,
  ) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot create address: config or token is missing.');
      return null;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.createAddressPath(),
        address,
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true ? responseData : null;
    } on AppException catch (e) {
      debugPrint('Error creating address: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred while creating address: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAddress(
    Map<String, dynamic> address,
  ) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot update address: config or token is missing.');
      return null;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.updateAddressPath(),
        address,
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true ? responseData : null;
    } on AppException catch (e) {
      debugPrint('Error updating address: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred while updating address: $e');
      return null;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot delete address: config or token is missing.');
      return false;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.deleteAddressPath(),
        <String, dynamic>{'address_id': addressId},
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true;
    } on AppException catch (e) {
      debugPrint('Error deleting address: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred while deleting address: $e');
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot set default address: config or token is missing.');
      return false;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.setDefaultAddressPath(),
        <String, dynamic>{'address_id': addressId},
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true;
    } on AppException catch (e) {
      debugPrint('Error setting default address: ${e.message}');
      return false;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while setting default address: $e',
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot fetch payment methods: config or token is missing.');
      return [];
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.listPaymentMethodsPath(),
        <String, dynamic>{},
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      final methods = responseData['payment_methods'] as List? ?? [];
      return methods
          .whereType<Map>()
          .map((method) => Map<String, dynamic>.from(method))
          .toList();
    } on AppException catch (e) {
      debugPrint('Error fetching payment methods: ${e.message}');
      if (e.statusCode == 401) {
        await _clearUserSessionAndLoadGuestCart();
        notifyListeners();
      }
      return [];
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while fetching payment methods: $e',
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> saveCardPaymentMethod({
    String? paymentMethodId,
    String? cardNumber,
    String? cardLast4,
    String? cardBrand,
    required int cardExpMonth,
    required int cardExpYear,
    String? billingCountry,
    String? billingPostalCode,
    String? displayLabel,
    bool isDefault = false,
  }) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint(
        'Cannot save card payment method: config or token is missing.',
      );
      return null;
    }

    final requestBody = <String, dynamic>{
      if (paymentMethodId != null && paymentMethodId.isNotEmpty)
        'payment_method_id': paymentMethodId,
      if (cardNumber != null && cardNumber.isNotEmpty)
        'card_number': cardNumber,
      if (cardLast4 != null && cardLast4.isNotEmpty) 'card_last4': cardLast4,
      if (cardBrand != null && cardBrand.isNotEmpty) 'card_brand': cardBrand,
      'card_exp_month': cardExpMonth,
      'card_exp_year': cardExpYear,
      if (billingCountry != null && billingCountry.isNotEmpty)
        'billing_country': billingCountry,
      if (billingPostalCode != null && billingPostalCode.isNotEmpty)
        'billing_postal_code': billingPostalCode,
      if (displayLabel != null && displayLabel.isNotEmpty)
        'display_label': displayLabel,
      'is_default': isDefault,
    };

    try {
      final rawResponse = await _apiService.post(
        _config!.saveCardPaymentMethodPath(),
        requestBody,
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true ? responseData : null;
    } on AppException catch (e) {
      debugPrint('Error saving card payment method: ${e.message}');
      return null;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while saving card payment method: $e',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> savePaypalPaymentMethod({
    String? paymentMethodId,
    required String paypalEmail,
    String? displayLabel,
    bool isDefault = false,
  }) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint(
        'Cannot save PayPal payment method: config or token is missing.',
      );
      return null;
    }

    final requestBody = <String, dynamic>{
      if (paymentMethodId != null && paymentMethodId.isNotEmpty)
        'payment_method_id': paymentMethodId,
      'paypal_email': paypalEmail.trim(),
      if (displayLabel != null && displayLabel.isNotEmpty)
        'display_label': displayLabel.trim(),
      'is_default': isDefault,
    };

    try {
      final rawResponse = await _apiService.post(
        _config!.savePaypalPaymentMethodPath(),
        requestBody,
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true ? responseData : null;
    } on AppException catch (e) {
      debugPrint('Error saving PayPal payment method: ${e.message}');
      return null;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while saving PayPal payment method: $e',
      );
      return null;
    }
  }

  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint('Cannot delete payment method: config or token is missing.');
      return false;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.deletePaymentMethodPath(),
        <String, dynamic>{'payment_method_id': paymentMethodId},
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true;
    } on AppException catch (e) {
      debugPrint('Error deleting payment method: ${e.message}');
      return false;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while deleting payment method: $e',
      );
      return false;
    }
  }

  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    if (_config == null || _userToken == null || _userToken!.isEmpty) {
      debugPrint(
        'Cannot set default payment method: config or token is missing.',
      );
      return false;
    }

    try {
      final rawResponse = await _apiService.post(
        _config!.setDefaultPaymentMethodPath(),
        <String, dynamic>{'payment_method_id': paymentMethodId},
        token: _userToken,
      );
      final responseData = rawResponse as Map<String, dynamic>;
      return responseData['success'] == true;
    } on AppException catch (e) {
      debugPrint('Error setting default payment method: ${e.message}');
      return false;
    } catch (e) {
      debugPrint(
        'An unexpected error occurred while setting default payment method: $e',
      );
      return false;
    }
  }

  String fetchImageRoot() {
    if (_config == null) return '';
    return _config!.getImagesRootUrl();
  }
}
