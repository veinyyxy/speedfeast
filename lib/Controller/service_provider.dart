// E:/flutter_project/speedfeast/lib/Controller/service_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Common/service_config.dart';
import 'api_service.dart';
import '../Security/collect_features.dart';

class ServiceProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ServiceConfig? _config;
  dynamic _initData;
  bool _isLoggedIn = false;
  String? _userToken;
  late ApiService _apiService;

  bool get isLoggedIn => _isLoggedIn;
  dynamic get initData => _initData;
  ServiceConfig? get config => _config;
  String? get userToken => _userToken;

  Map<String, String> features = {};
  bool _isInitialized = false;

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
    debugPrint('User status loaded: isLoggedIn=$_isLoggedIn, token=${_userToken != null ? "exists" : "null"}');
    notifyListeners();
  }

  Future<void> loginUser(String token) async {
    await _secureStorage.write(key: 'user_token', value: token);
    _userToken = token;
    _isLoggedIn = true;
    notifyListeners();
    debugPrint('User logged in. Token stored securely.');
    await fetchInitData();
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
      'target': emailOrPhone
    }; // Construct a Map
    try {
      final rawResponse = await _apiService.get(
        _config!.getVerificationCodePath(),
        queryParameters: queryParameters, // Use the new argument name and Map
        token: _userToken,
      );
      // 解析响应体，检查 'success' 字段
      final Map<String, dynamic> responseData = rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('Verification code sent successfully: ${responseData['message']}');
        return true; // 服务器指示成功
      } else {
        // 即使 HTTP 状态码是 200，但服务器业务逻辑指示失败
        String errorMessage = responseData['message']?.toString() ?? 'Server indicated failure to send verification code.';
        debugPrint('Server indicated failure: $errorMessage');
        return false;
      }
    } on AppException catch (e) {
      debugPrint('Error sending verification code: ${e.message}');
      return false; // 捕获到应用异常，返回 false
    } catch (e) {
      debugPrint('An unexpected error occurred while sending verification code: $e');
      return false; // 捕获到其他未知异常，返回 false
    }
  }

  // 修改 verifyVerificationCode 返回 Future<bool> (同样遵循 success 字段)
  Future<bool> verifyVerificationCode(String emailOrPhone, String code, String type
      , {Map<String, dynamic>? resData}) async {
    if (_config == null) {
      debugPrint('Config not loaded yet for verifyVerificationCode.');
      return false;
    }
    final Map<String, dynamic> queryParameters = {
        'type': type,
        'target': emailOrPhone,
        'code': code
    }; // Construct a Map
    try {
        final rawResponse = await _apiService.get(
          _config!.verifyVerificationCodePath(),
          queryParameters: queryParameters, // Use the new argument name and Map
          token: _userToken,
        );
      // 解析响应体，检查 'success' 字段
      final Map<String, dynamic> responseData = rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('Verification successful: ${responseData['message']}');
        resData?.addAll(responseData);
        return true; // 服务器指示成功
      } else {
        // 即使 HTTP 状态码是 200，但服务器业务逻辑指示失败
        String errorMessage = responseData['message']?.toString() ?? 'Server indicated verification failed.';
        debugPrint('Server indicated failure: $errorMessage');
        return false;
      }
    } on AppException catch (e) {
      debugPrint('Error verifying verification code: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('An unexpected error occurred while verifying verification code: $e');
      return false;
    }
  }

  // 新增：提交注册信息功能
  Future<bool> registerUser(String username, String phone, String email, String password) async {
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
        token: _userToken // 注册通常不需要token
      );

      final Map<String, dynamic> responseData = rawResponse as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('Registration successful: ${responseData['message']}');
        // 注册成功后，你可能需要自动登录用户或引导他们登录
        // 例如：loginUser(responseData['token'] as String);
        return true;
      } else {
        String errorMessage = responseData['message']?.toString() ?? 'Server indicated registration failed.';
        debugPrint('Server indicated failure during registration: $errorMessage');
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

  String fetchImageRoot() {
    if (_config == null) return '';
    return _config!.getImagesRootUrl();
  }
}