// E:/flutter_project/speedfeast/lib/Controller/service_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Common/service_config.dart';
import 'api_service.dart';
import '../Security/collect_features.dart';
import '../Common/order_item.dart';

class ServiceProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ServiceConfig? _config;
  dynamic _initData;
  bool _isLoggedIn = false;
  String? _userToken;
  String? _lastOrderError;
  String? _lastRecentOrdersError;
  late ApiService _apiService;

  bool get isLoggedIn => _isLoggedIn;
  dynamic get initData => _initData;
  ServiceConfig? get config => _config;
  String? get userToken => _userToken;
  String? get lastOrderError => _lastOrderError;
  String? get lastRecentOrdersError => _lastRecentOrdersError;

  Map<String, String> features = {};
  bool _isInitialized = false;

  // --- Cart Management ---
  final List<OrderItem> _cartItems = [];
  List<OrderItem> get cartItems => _cartItems;

  int get cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get cartSubtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

  void addToCart(OrderItem item) {
    final index = _cartItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _cartItems[index].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void setCartItemQuantity(OrderItem item, int quantity) {
    final index = _cartItems.indexWhere((i) => i.id == item.id);
    if (quantity <= 0) {
      if (index != -1) {
        _cartItems.removeAt(index);
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
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index].quantity += delta;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createOrder({
    required String fulfillmentType,
    String? tableNumber,
    String? pickupLocation,
    String? deliveryNote,
    Map<String, dynamic>? shippingAddress,
    String? shippingAddressId,
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
      'items': _cartItems
          .map(
            (item) => {'product_id': item.productId, 'quantity': item.quantity},
          )
          .toList(),
      if (shippingAddressId != null && shippingAddressId.isNotEmpty)
        'shipping_address_id': shippingAddressId,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (tableNumber != null && tableNumber.isNotEmpty)
        'table_number': tableNumber,
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
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
        _isLoggedIn = false;
        notifyListeners();
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('An unexpected error occurred while creating order: $e');
      debugPrint('Create order stack trace: $stackTrace');
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
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
        _isLoggedIn = false;
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

  ServiceProvider() {
    _loadUserStatus();
  }

  // ** 4. 新增异步初始化方法 **
  Future<void> initialize() async {
    if (_isInitialized) return; // 防止重复初始化

    debugPrint('ServiceProvider initialization started.');

    // 调用 collectFeatures() 并等待结果
    features = await collectFeatures();
    debugPrint('Security features collected: $features');

    // 加载用户状态 (此方法内部有 await)
    await _loadUserStatus();

    // 加载配置 (此方法内部有 await)
    await loadConfig();

    // 初始化完成后，可以尝试获取初始化数据
    await fetchInitData();

    _isInitialized = true;
    notifyListeners();
    debugPrint('ServiceProvider initialization finished.');
  }

  // --- 用户状态管理 ---
  Future<void> _loadUserStatus() async {
    _userToken = await _secureStorage.read(key: 'user_token');
    _isLoggedIn = _userToken != null && _userToken!.isNotEmpty;
    debugPrint(
      'User status loaded: isLoggedIn=$_isLoggedIn, token=${_userToken != null ? "exists" : "null"}',
    );
    notifyListeners();
  }

  Future<void> saveUserToken(String token) async {
    await _secureStorage.write(key: 'user_token', value: token);
    _userToken = token;
    _isLoggedIn = true;
    notifyListeners();
    debugPrint('User logged in. Token stored securely.');
    await fetchInitData();
  }

  Future<bool> loginUser({
    String? username,
    String? cellPhone,
    required String password,
  }) async {
    if (_config == null) {
      debugPrint('Config not loaded yet for loginUser.');
      return false;
    }
    if ((username == null || username.isEmpty) &&
        (cellPhone == null || cellPhone.isEmpty)) {
      debugPrint('Login failed: username or cell phone is required.');
      return false;
    }

    final Map<String, dynamic> requestBody = {
      'password': password,
      if (username != null && username.isNotEmpty) 'username': username,
      if (cellPhone != null && cellPhone.isNotEmpty) 'cell_phone': cellPhone,
    };

    try {
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
          return false;
        }

        await saveUserToken(token);
        debugPrint('Login successful: ${responseData['message']}');
        return true;
      }

      final errorMessage =
          responseData['error']?.toString() ??
          responseData['message']?.toString() ??
          'Server indicated login failed.';
      debugPrint('Server indicated login failure: $errorMessage');
      return false;
    } on AppException catch (e) {
      debugPrint('Error during user login: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred during user login: $e');
      return false;
    }
  }

  Future<bool> validateToken() async {
    if (_config == null) {
      debugPrint('Config not loaded yet for validateToken.');
      return false;
    }
    if (_userToken == null || _userToken!.isEmpty) {
      _isLoggedIn = false;
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
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
      }
      notifyListeners();
      debugPrint('Token validation result: $isValid');
      return isValid;
    } on AppException catch (e) {
      debugPrint('Error validating token: ${e.message}');
      if (e.statusCode == 400 || e.statusCode == 401) {
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
        _isLoggedIn = false;
        notifyListeners();
      }
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred while validating token: $e');
      return false;
    }
  }

  Future<void> logoutUser() async {
    await _secureStorage.delete(key: 'user_token');
    _userToken = null;
    _isLoggedIn = false;
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

    try {
      // 注册通常不需要用户Token，因为它发生在登录之前
      final rawResponse = await _apiService.post(
        _config!.getRegisterPath(), // 使用新的注册接口路径
        requestBody, // 将请求体传递给post方法
        token: _userToken, // 注册通常不需要token
      );

      final Map<String, dynamic> responseData =
          rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('Registration successful: ${responseData['message']}');
        // 注册成功后，你可能需要自动登录用户或引导他们登录
        // 例如：loginUser(responseData['token'] as String);
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
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
        _isLoggedIn = false;
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
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
        _isLoggedIn = false;
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
        await _secureStorage.delete(key: 'user_token');
        _userToken = null;
        _isLoggedIn = false;
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
