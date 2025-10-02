import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Common/service_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Security/make_request_header.dart';

class ServiceProvider with ChangeNotifier {
  ServiceConfig? config;
  dynamic initData;
  bool _isLoggedIn = false; // 初始为未登录
  bool get isLoggedIn => _isLoggedIn; // 提供一个 getter
  String get secretKeyHMAC => dotenv.env['HMAC_SECRET_KEY'] ?? '';
  String get clientID => dotenv.env['CLIENT_ID'] ?? '';
  String? _userToken;

  ServiceProvider() {
    _loadUserStatus(); // 构造函数中加载用户状态
  }

  Future<void> _loadUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _userToken = prefs.getString('user_token'); // 检查是否有保存的 token
    _isLoggedIn = _userToken != null && _userToken!.isNotEmpty;
    notifyListeners(); // 通知监听者
  }

  // 登录成功后调用此方法
  Future<void> loginUser(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', token);
    _userToken = token;
    _isLoggedIn = true;
    notifyListeners();
  }

  // 登出时调用此方法
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    _userToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> loadConfig() async {
    final jsonString = await rootBundle.loadString('assets/configs/web.json');
    final jsonMap = jsonDecode(jsonString);
    config = ServiceConfig.fromJson(jsonMap['service']);
    notifyListeners();
  }

  Map<String, String>? createHeaders(String params){
    if(secretKeyHMAC.length < 5 && clientID.length < 5) return null;
    final headerData = makeRequestHeader(clientID, secretKeyHMAC, null, 0);
    return headerData;
  }

  Future<void> fetchInitData() async {
    if (config == null) return;
    final headerData = createHeaders('');
    final url = Uri.parse(config!.getProductListUrl());
    final response = await http.get(url, headers: headerData);

    if (response.statusCode == 200) {
      initData = jsonDecode(response.body);
      notifyListeners();
    }
  }

  Future<void> sendVerificationCode(String emailOrPhone, String type) async {
    if (config == null) return;

    final params = 'type=$type&target=$emailOrPhone';
    final headerData = createHeaders(params);
    final url = Uri.parse('${config!.getVerificationCodeUrl()}?$params') ;
    final response = await http.get(url, headers: headerData);

    if (response.statusCode == 200) {
      initData = jsonDecode(response.body);
      notifyListeners();
    }
  }

  Future<void> verifyVerificationCode(String emailOrPhone, String code, String type) async {
    if (config == null) return;

    final params = 'type=$type&target=$emailOrPhone&code=$code';
    final headerData = createHeaders(params);
    final url = Uri.parse('${config!.verifyVerificationCodeUrl()}?$params') ;
    final response = await http.get(url, headers: headerData);
    if (response.statusCode == 200) {
      initData = jsonDecode(response.body);
      notifyListeners();
    }
  }

  String fetchImageRoot(){
    if (config == null) return '';
    return config!.getImagesRootUrl();
  }
}