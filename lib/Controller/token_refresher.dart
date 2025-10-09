// E:/flutter_project/speedfeast/lib/Controller/token_refresher.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'service_provider.dart'; // 导入你的 ServiceProvider

class TokenRefresher {
  final ServiceProvider _serviceProvider;
  Timer? _timer;
  final Duration _refreshInterval; // 刷新间隔

  // 构造函数，需要传入 ServiceProvider 实例和刷新间隔
  TokenRefresher(this._serviceProvider, {Duration refreshInterval = const Duration(minutes: 10)})
      : _refreshInterval = refreshInterval;

  // 启动定时器
  void start() {
    // 如果定时器已运行，先停止
    _timer?.cancel();

    // 立即执行一次刷新（可选，取决于你的需求）
    // _performTokenRefresh();

    // 启动周期性定时器
    _timer = Timer.periodic(_refreshInterval, (timer) {
      debugPrint('TokenRefresher: Timer triggered. Attempting to refresh/validate token...');
      _performTokenRefresh();
    });
    debugPrint('TokenRefresher: Started with interval: ${_refreshInterval.inMinutes} minutes.');
  }

  // 停止定时器
  void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('TokenRefresher: Stopped.');
  }

  // 执行 token 刷新或验证的实际逻辑
  Future<void> _performTokenRefresh() async {
    if (!_serviceProvider.isLoggedIn) {
      debugPrint('TokenRefresher: User not logged in, skipping token refresh.');
      return; // 如果用户未登录，则不执行刷新
    }

    if (_serviceProvider.config == null) {
      debugPrint('TokenRefresher: Service configuration not loaded yet, skipping token refresh.');
      return;
    }

    // 这里的逻辑取决于你的后端API如何处理token验证或刷新
    // 假设你的 `fetchInitData()` 方法会检查并刷新 token，
    // 或者你有一个专门的 `refreshToken()` 方法。
    // 如果你的 API 需要一个专门的 token 刷新端点，你需要先在 ServiceConfig 和 ApiService 中添加它。

    try {
      // 示例：调用一个可能刷新 token 的方法，或者只是验证当前 token 是否有效
      // 假设 fetchInitData 成功意味着 token 仍然有效或已被刷新
      await _serviceProvider.fetchInitData();
      debugPrint('TokenRefresher: Token refresh/validation successful.');
    } catch (e) {
      debugPrint('TokenRefresher: Failed to refresh/validate token: $e');
      // 如果 token 验证失败，你可能需要执行登出操作
      // await _serviceProvider.logoutUser();
      // debugPrint('TokenRefresher: User logged out due to token validation failure.');
    }
  }
}