import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// 现在 secretKey 的值就是 'YOUR_SUPER_SECRET_KEY_FROM_ENV'
/// 共享的秘密密钥，必须和服务端一致
/**
 * 使用 HMAC-SHA256 算法生成消息认证码
 * @param String data - 要签名的数据 (例如：JSON字符串)
 * @returns String - Base64 编码的 HMAC 签名
 */

String generateSignature(String data, String secretKey) {
  // 1. 密钥转为字节
  List<int> keyBytes = utf8.encode(secretKey);

  // 2. 数据转为字节
  List<int> dataBytes = utf8.encode(data);

  // 3. 创建 HMAC 实例
  var hmac = Hmac(sha256, keyBytes);

  // 4. 计算签名
  var digest = hmac.convert(dataBytes);

  // 5. 将结果转为 Base64 字符串
  return base64Encode(digest.bytes);
}

// 用于生成随机数的随机源
final Random _secureRandom = Random.secure();

/// 生成一个安全的、Base64URL 编码的 Nonce 随机字符串。
///
/// [length] 为随机字节的长度，不是最终字符串的长度。
/// 默认 16 字节（128 位）被认为是安全的。
String generateNonce([int length = 16]) {
  // 1. 生成安全随机字节列表
  // 使用 Random.secure() 来保证生成的高质量随机数。
  final List<int> randomBytes = List<int>.generate(length, (i) => _secureRandom.nextInt(256));

  // 2. 将随机字节进行 Base64 编码
  String nonce = base64Url.encode(randomBytes);

  // 3. 移除填充字符 '='
  // Base64URL 编码通常在末尾使用 '=' 字符进行填充。
  // 为了得到一个更简洁、更安全的 Nonce，我们通常移除这些填充字符。
  return nonce.replaceAll('=', '');
}

///type=0 表示是一个get请求的编码，type=1表示是一个post请求的编码
Map<String, String> makeRequestHeader(String clientID, String secretKey,
    Map<String, dynamic>? queryParameters, int type) {
  final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(); // 秒级时间戳
  final nonce = generateNonce();

  // 1. 将 Map<String, dynamic> 转换为规范化的查询字符串
  // 仅包含键值对，不带开头的 '?'
  // 重要的是：确保键和值在转换和签名过程中保持一致的排序和格式（例如，按键名排序）。
  String paramsString = "";

  if(queryParameters != null && type == 0) {
    paramsString = _normalizeQueryParameters(queryParameters);
  }
  else if(queryParameters != null && type == 1){
    paramsString = jsonEncode(queryParameters);
  }

  if (kDebugMode) {
    print("++++++++++++++normalizeQueryParameters:$paramsString");
  }
  // 2. 构造签名所需的数据
  String data = '$clientID-$timestamp-$nonce-$paramsString';
  if (kDebugMode) {
    print("++++++++++++++data:$data");
  }
  // 3. 生成签名
  final signature = generateSignature(data, secretKey);

  final headers = {
    'x-client-id': clientID,
    'x-timestamp': timestamp,
    'x-nonce': nonce,
    'x-signature': signature,
  };
  return headers;
}

// 辅助函数：用于将 Map<String, dynamic> 转换为规范化字符串
// ⚠️ 关键点：对键进行排序以确保签名的可预测性
String _normalizeQueryParameters(Map<String, dynamic>? parameters) {
  if (parameters == null || parameters.isEmpty) {
    return '';
  }

  // 1. 获取所有键并进行排序 (这是确保签名一致性的关键步骤)
  final sortedKeys = parameters.keys.toList()..sort();

  // 2. 构建规范化字符串
  // 注意：这里不进行 URL 编码，因为签名算法通常需要原始值。
  // 只有在构建最终的 URI 时才应该进行 URL 编码。
  final buffer = StringBuffer();
  for (var i = 0; i < sortedKeys.length; i++) {
    final key = sortedKeys[i];
    final value = parameters[key];

    // 将值转换为字符串，例如 List 或 null 需要特殊处理，
    // 这里简单地使用 toString()，但应根据实际API规范调整。
    String valueString = value.toString();

    buffer.write('$key=$valueString');
    if (i < sortedKeys.length - 1) {
      buffer.write('&');
    }
  }

  return buffer.toString();
}