class ServiceConfig {
  final Map<String, dynamic> function;
  final String _apiBaseUrl;

  ServiceConfig({
    required this.function,
    String apiBaseUrl = const String.fromEnvironment(
      'BUYER_API_BASE_URL',
      defaultValue: '',
    ),
  }) : _apiBaseUrl = apiBaseUrl;

  factory ServiceConfig.fromJson(
    Map<String, dynamic> json, {
    String apiBaseUrl = const String.fromEnvironment(
      'BUYER_API_BASE_URL',
      defaultValue: '',
    ),
  }) {
    return ServiceConfig(
      function: Map<String, dynamic>.from(json['function'] as Map? ?? {}),
      apiBaseUrl: apiBaseUrl,
    );
  }

  String _normalizeBaseUrl(String value, String source) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw FormatException(
        '$source must be an HTTP(S) origin without a path, query, or fragment.',
      );
    }
    return normalized;
  }

  String _url(String path) => '${getBaseUrl()}$path';

  String _path(String key, String fallback) {
    final value = function[key];
    if (value == null || value.toString().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String getProductListUrl() {
    return _url(getProductListPath());
  }

  String getStoresBootstrapUrl() {
    return _url(getStoresBootstrapPath());
  }

  String getVerificationCodeUrl() {
    return _url(getVerificationCodePath());
  }

  String verifyVerificationCodeUrl() {
    return _url(verifyVerificationCodePath());
  }

  String getRegisterUrl() {
    return _url(getRegisterPath());
  }

  String getLoginUrl() {
    return _url(getLoginPath());
  }

  String getValidateUrl() {
    return _url(getValidatePath());
  }

  String getCreateOrderUrl() {
    return _url(getCreateOrderPath());
  }

  String getVerifyDineInTableUrl() {
    return _url(getVerifyDineInTablePath());
  }

  String getCreatePaymentUrl() {
    return _url(getCreatePaymentPath());
  }

  String getCancelOrderUrl() {
    return _url(getCancelOrderPath());
  }

  String getRecentOrdersUrl() {
    return _url(getRecentOrdersPath());
  }

  String getRewardsSummaryUrl() {
    return _url(getRewardsSummaryPath());
  }

  String getRewardsTransactionsUrl() {
    return _url(getRewardsTransactionsPath());
  }

  String getRewardsRedemptionsUrl() {
    return _url(getRewardsRedemptionsPath());
  }

  String getRewardsRedeemUrl() {
    return _url(getRewardsRedeemPath());
  }

  String getOrderReviewUrl(String orderId) {
    return _url(getOrderReviewPath(orderId));
  }

  String getPersonalInfoUrl() {
    return _url(getPersonalInfoPath());
  }

  String getSystemConfigUrl() {
    return _url(getSystemConfigPath());
  }

  String getImagesRootUrl() {
    return getBaseUrl();
  }

  String getBaseUrl() {
    if (_apiBaseUrl.trim().isEmpty) {
      throw const FormatException(
        'BUYER_API_BASE_URL is required. Provide it with --dart-define.',
      );
    }
    return _normalizeBaseUrl(_apiBaseUrl, 'BUYER_API_BASE_URL');
  }

  String getProductListPath() =>
      _path('getProductList', '/api/products/get_list');
  String getStoresBootstrapPath() =>
      _path('storesBootstrap', '/api/stores/bootstrap');
  String getVerificationCodePath() =>
      _path('sendVerificationCode', '/api/verification/send_verification');
  String verifyVerificationCodePath() =>
      _path('verifyVerificationCode', '/api/verification/verify');
  String getRegisterPath() => _path('register', '/api/users/register');
  String getLoginPath() => _path('login', '/api/users/login');
  String getValidatePath() => _path('validate', '/api/user/validate');
  String getCreateOrderPath() => _path('createOrder', '/api/orders/create');
  String getVerifyDineInTablePath() =>
      _path('verifyDineInTable', '/api/dine-in/table/verify');
  String getCreatePaymentPath() =>
      _path('createPayment', '/api/payments/create');
  String getPaymentStatusPath() =>
      _path('getPaymentStatus', '/api/payments/status');
  String getSystemConfigPath() => _path('systemConfig', '/api/config');
  String getCancelOrderPath() => _path('cancelOrder', '/api/orders/cancel');
  String getRecentOrdersPath() =>
      _path('listRecentOrders', '/api/orders/get_list');
  String getRewardsSummaryPath() =>
      _path('rewardsSummary', '/api/rewards/summary');
  String getRewardsTransactionsPath() =>
      _path('rewardsTransactions', '/api/rewards/transactions');
  String getRewardsRedemptionsPath() =>
      _path('rewardsRedemptions', '/api/rewards/redemptions');
  String getRewardsRedeemPath() =>
      _path('rewardsRedeem', '/api/rewards/redeem');
  String getOrderReviewBasePath() =>
      _path('orderReview', '/api/reviews/orders');
  String getOrderReviewPath(String orderId) =>
      '${getOrderReviewBasePath()}/${Uri.encodeComponent(orderId)}';
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
  String listBuyerNotificationsPath() =>
      _path('listBuyerNotifications', '/api/buyer/notifications');
  String buyerNotificationUnreadCountPath() => _path(
    'buyerNotificationUnreadCount',
    '/api/buyer/notifications/unread-count',
  );
  String registerBuyerNotificationTokenPath() => _path(
    'registerBuyerNotificationToken',
    '/api/buyer/notifications/device-token',
  );
  String deactivateBuyerNotificationTokenPath() => _path(
    'deactivateBuyerNotificationToken',
    '/api/buyer/notifications/device-token/deactivate',
  );
  String markBuyerNotificationReadPath(String notificationId) =>
      '${_path('markBuyerNotificationRead', '/api/buyer/notifications')}/${Uri.encodeComponent(notificationId)}/read';
  String deleteBuyerNotificationPath(String notificationId) =>
      '${_path('deleteBuyerNotification', '/api/buyer/notifications')}/${Uri.encodeComponent(notificationId)}/delete';
  String markAllBuyerNotificationsReadPath() => _path(
    'markAllBuyerNotificationsRead',
    '/api/buyer/notifications/read-all',
  );
  String deleteReadBuyerNotificationsPath() => _path(
    'deleteReadBuyerNotifications',
    '/api/buyer/notifications/delete-read',
  );
}
