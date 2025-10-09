// 假设这是你的 collect_features.dart 文件内容
import 'package:flutter/foundation.dart'; // 【新增】引入 kIsWeb 来判断是否为 Web
// 保留 dart:io 导入，但必须确保其 API 仅在非 Web 环境下被调用
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// collectFeatures() 是你的实际函数
Future<Map<String, String>> collectFeatures() async {
  final deviceInfo = DeviceInfoPlugin();
  final packageInfo = await PackageInfo.fromPlatform();

  String platform = '';
  String model = '';
  String osVersion = '';

  // --- 修正后的跨平台逻辑：使用 kIsWeb 优先处理 Web 平台 ---

  // 1. 优先检查 Web 平台 (Web 环境下 dart:io 的 Platform.isX 会抛出异常)
  if (kIsWeb) {
    try {
      // 在 Web 上使用 device_info_plus 的 webBrowserInfo
      final info = await deviceInfo.webBrowserInfo;
      platform = 'Web';
      // userAgent 在 web 上收集可能包含安全敏感信息，这里仅作演示
      model = info.userAgent ?? 'Unknown Browser/User Agent';
      osVersion = '${info.browserName.name} ${info.appVersion ?? ''}';
    } catch (e) {
      // 即使获取 Web Info 失败，至少平台是 Web
      platform = 'Web';
      model = 'Web Platform Error: $e';
      osVersion = 'N/A';
    }
  }
  // 2. 检查移动/桌面平台 (只有在非 Web 环境下，Platform 才是安全的)
  else {
    // 在这里调用 Platform.isX 是安全的，因为我们已经排除了 Web 环境
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      platform = 'Android';
      model = info.model ?? '';
      osVersion = info.version.release ?? '';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      platform = 'iOS';
      model = info.utsname.machine ?? '';
      osVersion = info.systemVersion ?? '';
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      platform = 'Windows';
      model = info.computerName ?? '';
      osVersion = '${info.productName} ${info.buildNumber}';
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      platform = 'Linux';
      model = info.prettyName ?? '';
      osVersion = info.version ?? '';
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      platform = 'macOS';
      model = info.model ?? '';
      osVersion = info.osRelease ?? '';
    } else {
      // 兜底情况
      platform = 'Unknown Native';
      model = 'Unknown Model';
      osVersion = 'Unknown Version';
    }
  }

  return {
    'platform': platform,
    'model': model,
    'osVersion': osVersion,
    'packageName': packageInfo.packageName,
    'version': packageInfo.version,
  };
}
