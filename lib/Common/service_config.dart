class ServiceConfig {
  final String name;
  final int port;
  final Map<String, dynamic> function;

  ServiceConfig({
    required this.name,
    required this.port,
    required this.function,
  });

  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    return ServiceConfig(
      name: json['name']?.toString() ?? '',
      port: json['port'] is int
          ? json['port'] as int
          : int.tryParse(json['port']?.toString() ?? '') ?? 0,
      function: Map<String, dynamic>.from(json['function'] as Map? ?? {}),
    );
  }

  String _path(String key, String fallback) {
    final value = function[key];
    if (value == null || value.toString().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String getProductListUrl() {
    return '$name:$port${getProductListPath()}';
  }

  String getVerificationCodeUrl() {
    return '$name:$port${getVerificationCodePath()}';
  }

  String verifyVerificationCodeUrl() {
    return '$name:$port${verifyVerificationCodePath()}';
  }

  String getRegisterUrl() {
    return '$name:$port${getRegisterPath()}';
  }

  String getLoginUrl() {
    return '$name:$port${getLoginPath()}';
  }

  String getValidateUrl() {
    return '$name:$port${getValidatePath()}';
  }

  String getCreateOrderUrl() {
    return '$name:$port${getCreateOrderPath()}';
  }

  String getRecentOrdersUrl() {
    return '$name:$port${getRecentOrdersPath()}';
  }

  String getPersonalInfoUrl() {
    return '$name:$port${getPersonalInfoPath()}';
  }

  String getImagesRootUrl() {
    return '$name:$port';
  }

  String getBaseUrl() {
    return '$name:$port';
  }

  String getProductListPath() =>
      _path('getProductList', '/api/products/get_list');
  String getVerificationCodePath() =>
      _path('sendVerificationCode', '/api/verification/send_verification');
  String verifyVerificationCodePath() =>
      _path('verifyVerificationCode', '/api/verification/verify');
  String getRegisterPath() => _path('register', '/api/users/register');
  String getLoginPath() => _path('login', '/api/users/login');
  String getValidatePath() => _path('validate', '/api/user/validate');
  String getCreateOrderPath() => _path('createOrder', '/api/orders/create');
  String getRecentOrdersPath() =>
      _path('listRecentOrders', '/api/orders/get_list');
  String getPersonalInfoPath() =>
      _path('getPersonalInfo', '/api/users/profile/get');
  String updatePersonalInfoPath() =>
      _path('updatePersonalInfo', '/api/users/profile/update');
  String createAddressPath() =>
      _path('createAddress', '/api/users/address/create');
  String updateAddressPath() =>
      _path('updateAddress', '/api/users/address/update');
  String deleteAddressPath() =>
      _path('deleteAddress', '/api/users/address/delete');
  String setDefaultAddressPath() =>
      _path('setDefaultAddress', '/api/users/address/default');
  String listPaymentMethodsPath() =>
      _path('listPaymentMethods', '/api/payment-methods/list');
  String saveCardPaymentMethodPath() =>
      _path('saveCardPaymentMethod', '/api/payment-methods/card/save');
  String savePaypalPaymentMethodPath() =>
      _path('savePaypalPaymentMethod', '/api/payment-methods/paypal/save');
  String deletePaymentMethodPath() =>
      _path('deletePaymentMethod', '/api/payment-methods/delete');
  String setDefaultPaymentMethodPath() =>
      _path('setDefaultPaymentMethod', '/api/payment-methods/default');
}
