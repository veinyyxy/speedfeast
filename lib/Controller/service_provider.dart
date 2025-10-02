// E:/flutter_project/speedfeast/lib/Controller/service_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../Common/service_config.dart';
import 'api_service.dart';

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

  ServiceProvider() {
    _loadUserStatus();
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
      debugPrint('Initial data fetched: $_initData');
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
  Future<bool> verifyVerificationCode(String emailOrPhone, String code, String type) async {
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
        // 如果验证成功，并且 API 返回了 token，则可以在这里调用 loginUser
        // if (responseData['token'] != null) {
        //   await loginUser(responseData['token']);
        // }
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

  String fetchImageRoot() {
    if (_config == null) return '';
    return _config!.getImagesRootUrl();
  }
}