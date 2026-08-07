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
const String androidApkDownloadUrl =
    '$gatewayUrl/api/v1/app/download/android';

/// 对应 `GET /api/v1/app/releases/latest` 的 data 解析结果。
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.channel,
    required this.updateType,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.releaseNotes,
    required this.downloadUrl,
    this.fileUrl = '',
    this.fileName = '',
    this.fileSize = 0,
    this.publishedAt = '',
    this.forceUpdate = false,
    // 兼容旧构造参数（门禁单测等）
    this.minimumVersion = '',
    this.minimumVersionCode = 0,
  });

  /// 解析接口文档中的 `data`：
  /// ```json
  /// {
  ///   "release": {
  ///     "version": "1.5.0",
  ///     "version_code": 15,
  ///     "release_notes": "更新说明",
  ///     "file_url": "https://assets.dinq.me/...apk",
  ///     "file_name": "dinq-1.5.0.apk",
  ///     "file_size": 123456789,
  ///     "published_at": "2026-08-06T10:00:00Z",
  ///     "force_update": false
  ///   },
  ///   "stable_download_url": "/api/v1/app/download/android"
  /// }
  /// ```
  factory AppUpdateInfo.fromLatestRelease(
    Map<String, dynamic> data, {
    required int currentVersionCode,
    String fallbackChannel = distributionChannel,
  }) {
    final release = data['release'];
    if (release is! Map) {
      return AppUpdateInfo(
        platform: 'android',
        channel: fallbackChannel,
        updateType: AppUpdateType.none,
        latestVersion: '',
        latestVersionCode: 0,
        releaseNotes: '',
        downloadUrl: androidApkDownloadUrl,
      );
    }

    final releaseMap = Map<String, dynamic>.from(release);
    final version = releaseMap['version']?.toString() ?? '';
    final versionCode = _asInt(releaseMap['version_code']);
    final releaseNotes = releaseMap['release_notes']?.toString() ?? '';
    final fileUrl = releaseMap['file_url']?.toString() ?? '';
    final fileName = releaseMap['file_name']?.toString() ?? '';
    final fileSize = _asInt(releaseMap['file_size']);
    final publishedAt = releaseMap['published_at']?.toString() ?? '';
    final forceUpdate = _asBool(releaseMap['force_update']);
    final platform = releaseMap['platform']?.toString() ?? 'android';
    final channel = releaseMap['channel']?.toString() ?? fallbackChannel;

    final stablePath = data['stable_download_url']?.toString() ?? '';
    final downloadUrl = _resolveStableDownloadUrl(stablePath);

    // 本地 version_code 落后最新版 → 需要更新；是否强制看 force_update
    final needsUpdate = versionCode > currentVersionCode;
    final updateType = !needsUpdate
        ? AppUpdateType.none
        : (forceUpdate ? AppUpdateType.force : AppUpdateType.optional);

    return AppUpdateInfo(
      platform: platform,
      channel: channel,
      updateType: updateType,
      latestVersion: version,
      latestVersionCode: versionCode,
      releaseNotes: releaseNotes,
      downloadUrl: downloadUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      publishedAt: publishedAt,
      forceUpdate: forceUpdate,
      minimumVersion: forceUpdate ? version : '',
      minimumVersionCode: forceUpdate ? versionCode : 0,
    );
  }

  final String platform;
  final String channel;
  final AppUpdateType updateType;
  final String latestVersion;
  final int latestVersionCode;
  final String releaseNotes;

  /// 由 `stable_download_url` 解析出的绝对下载地址。
  final String downloadUrl;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String publishedAt;
  final bool forceUpdate;

  final String minimumVersion;
  final int minimumVersionCode;

  bool get isForceUpdate => updateType == AppUpdateType.force;

  bool get shouldShowPrompt =>
      updateType == AppUpdateType.force ||
      (updateType == AppUpdateType.optional && channel != 'google_play');

  /// 下载按钮始终使用固定下载地址（接口文档约定）。
  String get effectiveDownloadUrl {
    if (channel == 'google_play') {
      return fileUrl.isNotEmpty
          ? fileUrl
          : (downloadUrl.isNotEmpty ? downloadUrl : androidApkDownloadUrl);
    }
    return androidApkDownloadUrl;
  }

  static String _resolveStableDownloadUrl(String stablePath) {
    if (stablePath.isEmpty) return androidApkDownloadUrl;
    if (stablePath.startsWith('http')) return stablePath;
    if (stablePath.startsWith('/')) return '$gatewayUrl$stablePath';
    return androidApkDownloadUrl;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}

abstract interface class AppUpdateChecker {
  Future<AppUpdateInfo?> check();
}

typedef FetchLatestRelease =
    Future<Map<String, dynamic>?> Function(String platform, String channel);

class AppUpdateService implements AppUpdateChecker {
  AppUpdateService({
    PackageInfo? packageInfo,
    String channel = distributionChannel,
    FetchLatestRelease? fetchLatestRelease,
    bool? isAndroid,
  }) : _packageInfo = packageInfo,
       _channel = channel,
       _fetchLatestRelease = fetchLatestRelease,
       _isAndroid = isAndroid;

  PackageInfo? _packageInfo;
  final String _channel;
  final FetchLatestRelease? _fetchLatestRelease;
  final bool? _isAndroid;

  @override
  Future<AppUpdateInfo?> check() async {
    if (_isAndroid == false ||
        (_isAndroid == null &&
            (kIsWeb || defaultTargetPlatform != TargetPlatform.android))) {
      return null;
    }

    try {
      return (await checkManually()).info;
    } catch (_) {
      // 接口失败 fail-open，避免把用户锁死在门禁外。
      return null;
    }
  }

  /// 手动检测：请求 `GET /api/v1/app/releases/latest`。
  Future<AppUpdateManualResult> checkManually() async {
    final packageInfo = _packageInfo ??= await PackageInfo.fromPlatform();
    final versionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    if (versionCode < 1) {
      throw StateError('Invalid app version code.');
    }

    final platform = (_isAndroid == false ||
            (_isAndroid == null && defaultTargetPlatform == TargetPlatform.iOS))
        ? 'ios'
        : 'android';

    // ApiClient 会把 {code:0,data:...} 解包为 data
    final data = _fetchLatestRelease != null
        ? await _fetchLatestRelease(platform, _channel)
        : (await ApiClient.instance.dio.get<Map<String, dynamic>>(
            '/app/releases/latest',
          )).data;

    if (data == null) {
      throw StateError('Empty release response.');
    }

    return AppUpdateManualResult(
      info: AppUpdateInfo.fromLatestRelease(
        data,
        currentVersionCode: versionCode,
        fallbackChannel: _channel,
      ),
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
