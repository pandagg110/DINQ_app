import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';
import 'api_client.dart';

enum AppUpdateType { none, optional, force }

const String distributionChannel = String.fromEnvironment(
  'DISTRIBUTION_CHANNEL',
  defaultValue: 'official_apk',
);

/// 固定下载地址：`GET /api/v1/app/download/android`（307 到最新 APK）。
const String androidApkDownloadUrl = '$gatewayUrl/api/v1/app/download/android';

/// 对应 `GET /api/v1/app/version` 的 data 解析结果。
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.channel,
    required this.updateType,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.releaseNotes,
    required this.downloadUrl,
    this.minimumVersion = '',
    this.minimumVersionCode = 0,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawType = json['update_type']?.toString();
    final updateType = switch (rawType) {
      'force' => AppUpdateType.force,
      'optional' => AppUpdateType.optional,
      _ => AppUpdateType.none,
    };
    return AppUpdateInfo(
      platform: json['platform']?.toString() ?? 'android',
      channel: json['channel']?.toString() ?? distributionChannel,
      updateType: updateType,
      latestVersion: json['latest_version']?.toString() ?? '',
      latestVersionCode: _asInt(json['latest_version_code']),
      minimumVersion: json['minimum_version']?.toString() ?? '',
      minimumVersionCode: _asInt(json['minimum_version_code']),
      releaseNotes: json['release_notes']?.toString() ?? '',
      downloadUrl: json['download_url']?.toString() ?? '',
    );
  }

  final String platform;
  final String channel;
  final AppUpdateType updateType;
  final String latestVersion;
  final int latestVersionCode;
  final String releaseNotes;

  /// 版本接口返回的更新下载地址。
  final String downloadUrl;
  final String minimumVersion;
  final int minimumVersionCode;

  bool get isForceUpdate => updateType == AppUpdateType.force;

  bool get shouldShowPrompt => updateType != AppUpdateType.none;

  /// 优先使用版本接口返回的地址；缺失时回退到官方 APK 固定地址。
  String get effectiveDownloadUrl {
    if (downloadUrl.isNotEmpty) return downloadUrl;
    return platform == 'android' ? androidApkDownloadUrl : '';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

abstract interface class AppUpdateChecker {
  Future<AppUpdateInfo?> check();
}

typedef FetchAppVersion =
    Future<Map<String, dynamic>?> Function(
      String platform,
      String channel,
      int versionCode,
    );

class AppUpdateService implements AppUpdateChecker {
  AppUpdateService({
    PackageInfo? packageInfo,
    String channel = distributionChannel,
    FetchAppVersion? fetchVersion,
    bool? isAndroid,
  }) : _packageInfo = packageInfo,
       _channel = channel,
       _fetchVersion = fetchVersion,
       _isAndroid = isAndroid;

  PackageInfo? _packageInfo;
  final String _channel;
  final FetchAppVersion? _fetchVersion;
  final bool? _isAndroid;

  @override
  Future<AppUpdateInfo?> check() async {
    final isSupportedPlatform =
        _isAndroid != null ||
        (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS));
    if (!isSupportedPlatform) {
      return null;
    }

    try {
      return (await checkManually()).info;
    } catch (_) {
      // 接口失败 fail-open，避免把用户锁死在门禁外。
      return null;
    }
  }

  /// 手动检测：请求 `GET /api/v1/app/version`。
  Future<AppUpdateManualResult> checkManually() async {
    final packageInfo = _packageInfo ??= await PackageInfo.fromPlatform();
    final versionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    if (versionCode < 1) {
      throw StateError('Invalid app version code.');
    }

    final platform =
        (_isAndroid == false ||
            (_isAndroid == null && defaultTargetPlatform == TargetPlatform.iOS))
        ? 'ios'
        : 'android';

    // ApiClient 会把 {code:0,data:...} 解包为 data。
    final data = _fetchVersion != null
        ? await _fetchVersion(platform, _channel, versionCode)
        : (await ApiClient.instance.dio.get<Map<String, dynamic>>(
            '/app/version',
            queryParameters: {
              'platform': platform,
              'channel': _channel,
              'version_code': versionCode,
            },
          )).data;

    if (data == null) {
      throw StateError('Empty app version response.');
    }

    return AppUpdateManualResult(
      info: AppUpdateInfo.fromJson(data),
      currentVersion: packageInfo.version,
      currentVersionCode: versionCode,
    );
  }
}

class AppUpdateManualResult {
  const AppUpdateManualResult({
    required this.info,
    required this.currentVersion,
    required this.currentVersionCode,
  });

  final AppUpdateInfo info;
  final String currentVersion;
  final int currentVersionCode;
}
