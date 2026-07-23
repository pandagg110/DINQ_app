import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_client.dart';

enum AppUpdateType { none, optional, force }

const String distributionChannel = String.fromEnvironment(
  'DISTRIBUTION_CHANNEL',
  defaultValue: 'official_apk',
);

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.channel,
    required this.updateType,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.minimumVersion,
    required this.minimumVersionCode,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawType = json['update_type']?.toString();
    final type = switch (rawType) {
      'optional' => AppUpdateType.optional,
      'force' => AppUpdateType.force,
      _ => AppUpdateType.none,
    };
    return AppUpdateInfo(
      platform: json['platform']?.toString() ?? 'android',
      channel: json['channel']?.toString() ?? distributionChannel,
      updateType: type,
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
  final String minimumVersion;
  final int minimumVersionCode;
  final String releaseNotes;
  final String downloadUrl;

  bool get isForceUpdate => updateType == AppUpdateType.force;

  bool get shouldShowPrompt =>
      isForceUpdate ||
      (updateType == AppUpdateType.optional && channel != 'google_play');

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

abstract interface class AppUpdateChecker {
  Future<AppUpdateInfo?> check();
}

typedef FetchAppVersion =
    Future<Map<String, dynamic>?> Function(int versionCode, String channel);

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
    if (_isAndroid == false ||
        (_isAndroid == null &&
            (kIsWeb || defaultTargetPlatform != TargetPlatform.android))) {
      return null;
    }

    try {
      final packageInfo = _packageInfo ??= await PackageInfo.fromPlatform();
      final versionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      if (versionCode < 1) return null;

      final data = _fetchVersion != null
          ? await _fetchVersion(versionCode, _channel)
          : (await ApiClient.instance.dio.get<Map<String, dynamic>>(
              '/app/version',
              queryParameters: {
                'platform': 'android',
                'channel': _channel,
                'version_code': versionCode,
              },
            )).data;
      return data == null ? null : AppUpdateInfo.fromJson(data);
    } catch (_) {
      // Version checks fail open. A transient backend outage must not lock users out.
      return null;
    }
  }
}
