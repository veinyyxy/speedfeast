import 'package:flutter_test/flutter_test.dart';
import 'package:speedfeast/Common/service_config.dart';

void main() {
  final json = <String, dynamic>{
    'function': <String, dynamic>{'login': '/api/users/login'},
  };

  test('requires BUYER_API_BASE_URL when no API URL is injected', () {
    final config = ServiceConfig.fromJson(json, apiBaseUrl: '');

    expect(config.getBaseUrl, throwsFormatException);
  });

  test('accepts a local HTTP origin injected with dart-define', () {
    final config = ServiceConfig.fromJson(
      json,
      apiBaseUrl: 'http://192.168.100.103:3000',
    );

    expect(config.getBaseUrl(), 'http://192.168.100.103:3000');
    expect(config.getLoginUrl(), 'http://192.168.100.103:3000/api/users/login');
  });

  test('uses BUYER_API_BASE_URL without appending the JSON port', () {
    final config = ServiceConfig.fromJson(
      json,
      apiBaseUrl: '  https://api.techlong.cloud/  ',
    );

    expect(config.getBaseUrl(), 'https://api.techlong.cloud');
    expect(config.getImagesRootUrl(), 'https://api.techlong.cloud');
    expect(config.getLoginUrl(), 'https://api.techlong.cloud/api/users/login');
  });

  test('rejects an invalid injected API URL', () {
    final config = ServiceConfig.fromJson(
      json,
      apiBaseUrl: 'api.techlong.cloud',
    );

    expect(config.getBaseUrl, throwsFormatException);
  });

  test('preserves an explicitly configured HTTPS port', () {
    final config = ServiceConfig.fromJson(
      json,
      apiBaseUrl: 'https://api.techlong.cloud:8443',
    );

    expect(config.getBaseUrl(), 'https://api.techlong.cloud:8443');
  });

  test('rejects a base URL containing a path, query, or fragment', () {
    for (final apiBaseUrl in <String>[
      'https://api.techlong.cloud/v1',
      'https://api.techlong.cloud?debug=true',
      'https://api.techlong.cloud#api',
    ]) {
      final config = ServiceConfig.fromJson(json, apiBaseUrl: apiBaseUrl);
      expect(config.getBaseUrl, throwsFormatException);
    }
  });
}
