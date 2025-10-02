// lib/Service/api_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 用于获取 HMAC 密钥等
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:speedfeast/Security/make_request_header.dart';

// 自定义异常类
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'AppException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}

class ApiService {
  final String? _baseUrl;
  final String _secretKeyHMAC;
  final String _clientID;

  ApiService(this._baseUrl)
      : _secretKeyHMAC = dotenv.env['HMAC_SECRET_KEY'] ?? '',
        _clientID = dotenv.env['CLIENT_ID'] ?? '';

  // 内部辅助方法：创建 HMAC 签名头部
  Map<String, String> _createRequestHeaders(Map<String, dynamic>? queryParameters, int type) {
    if (_secretKeyHMAC.length < 5 || _clientID.length < 5) {
      throw AppException(
          "Security keys (HMAC_SECRET_KEY or CLIENT_ID) are not configured properly.");
    }

    return makeRequestHeader(_clientID, _secretKeyHMAC, queryParameters, type);
  }

  // **辅助函数：获取签名（假设这个函数存在于 make_request_header.dart 或类似地方）**
  // 我将它放在这里以完成示例，实际中应从 make_request_header.dart 导入
  /*String generateSignature(String data, String secretKey) {
    // This is a placeholder, replace with your actual HMAC logic
    // Example: HMAC SHA256
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return base64UrlEncode(digest.bytes);
  }*/

  // **辅助函数：生成 Nonce（假设这个函数存在于 make_request_header.dart 或类似地方）**
  // 我将它放在这里以完成示例，实际中应从 make_request_header.dart 导入
  /*String generateNonce([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }*/

  // 通用 GET 请求
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, String? token}) async {
    if (_baseUrl == null) {
      throw AppException("Service base URL is not configured.");
    }

    // 1. 使用 Uri.https/http 构造函数安全地处理查询参数
    // Uri 类会自动对 Map 中的键和值进行 URL 编码
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);
    print("---------------uri:$uri");
    // 注意：_createRequestHeaders(queryParams) 中的 queryParams 也需要相应修改
    // 如果你的签名逻辑需要原始的 query string，你可能需要单独处理
    // 这里假设签名逻辑需要的是 Map<String, dynamic>
    final Map<String, String> headers = _createRequestHeaders(queryParameters, 0);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw AppException('Network error: ${e.message}');
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }
  /*Future<dynamic> get(String path, {String? queryParams, String? token}) async {
    if (_baseUrl == null) {
      throw AppException("Service base URL is not configured.");
    }

    final uri = Uri.parse(
        '$_baseUrl$path${queryParams != null ? '?$queryParams' : ''}');

    // 生成签名所需的 dataToSign 应该包含 queryParams
    final Map<String, String> headers = _createRequestHeaders(queryParams);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw AppException('Network error: ${e.message}');
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }*/

  // 通用 POST 请求 (示例，如果你有 POST 请求)
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {String? token}) async {
    if (_baseUrl == null) {
      throw AppException("Service base URL is not configured.");
    }

    final uri = Uri.parse('$_baseUrl$path');
    final encodedBody = jsonEncode(body);

    // 生成签名所需的 dataToSign 应该包含 encodedBody
    // 这可能需要修改 generateSignature 来处理请求体
    final Map<String, String> headers = _createRequestHeaders(
        body, 1); // 假设签名也包含了body
    headers['Content-Type'] = 'application/json';
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.post(
          uri, headers: headers, body: encodedBody);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw AppException('Network error: ${e.message}');
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }

  // 统一响应处理
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return {}; // 返回空对象如果响应体为空
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      String errorMessage = 'Client error';
      if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body;
        }
      }
      throw AppException(errorMessage, statusCode: response.statusCode);
    } else if (response.statusCode >= 500) {
      throw AppException('Server error (Status: ${response.statusCode})',
          statusCode: response.statusCode);
    } else {
      throw AppException('Unknown error (Status: ${response.statusCode})',
          statusCode: response.statusCode);
    }
  }
}