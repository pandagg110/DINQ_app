import 'package:dinq_app/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 与接口文档对齐的响应 data 示例。
Map<String, dynamic> _latestPayload({
  String version = '1.5.0',
  int versionCode = 15,
  bool forceUpdate = false,
  String channel = 'official_apk',
  String notes = '更新说明',
}) {
  return {
    'release': {
      'version': version,
      'version_code': versionCode,
      'release_notes': notes,
      'file_url': 'https://assets.dinq.me/...apk',
      'file_name': 'dinq-1.5.0.apk',
      'file_size': 123456789,
      'published_at': '2026-08-06T10:00:00Z',
      'force_update': forceUpdate,
      'platform': 'android',
      'channel': channel,
    },
    'stable_download_url': '/api/v1/app/download/android',
  };
}

void main() {
  test('parses documented latest release fields', () {
    final info = AppUpdateInfo.fromLatestRelease(
      _latestPayload(forceUpdate: false),
      currentVersionCode: 10,
    );

    expect(info.latestVersion, '1.5.0');
    expect(info.latestVersionCode, 15);
    expect(info.releaseNotes, '更新说明');
    expect(info.fileName, 'dinq-1.5.0.apk');
    expect(info.fileSize, 123456789);
    expect(info.publishedAt, '2026-08-06T10:00:00Z');
    expect(info.forceUpdate, isFalse);
    expect(info.updateType, AppUpdateType.optional);
    expect(
      info.effectiveDownloadUrl,
      'https://api.dinq.me/api/v1/app/download/android',
    );
  });

  test('force_update=true shows force prompt when behind', () {
    final info = AppUpdateInfo.fromLatestRelease(
      _latestPayload(forceUpdate: true),
      currentVersionCode: 10,
    );

    expect(info.updateType, AppUpdateType.force);
    expect(info.isForceUpdate, isTrue);
    expect(info.shouldShowPrompt, isTrue);
  });

  test('no prompt when local version_code is up to date', () {
    final info = AppUpdateInfo.fromLatestRelease(
      _latestPayload(versionCode: 15, forceUpdate: true),
      currentVersionCode: 15,
    );

    expect(info.updateType, AppUpdateType.none);
    expect(info.shouldShowPrompt, isFalse);
  });

  test('Google Play optional updates do not use the DINQ prompt', () {
    final info = AppUpdateInfo.fromLatestRelease(
      _latestPayload(forceUpdate: false, channel: 'google_play'),
      currentVersionCode: 10,
    );

    expect(info.updateType, AppUpdateType.optional);
    expect(info.shouldShowPrompt, isFalse);
  });

  test('fetches /app/releases/latest', () async {
    var called = false;
    final service = AppUpdateService(
      isAndroid: true,
      channel: 'official_apk',
      packageInfo: PackageInfo(
        appName: 'DINQ',
        packageName: 'me.dinq.app',
        version: '1.0.0',
        buildNumber: '10',
      ),
      fetchLatestRelease: (platform, channel) async {
        called = true;
        expect(platform, 'android');
        return _latestPayload(forceUpdate: false);
      },
    );

    final info = await service.check();

    expect(called, isTrue);
    expect(info?.updateType, AppUpdateType.optional);
    expect(info?.releaseNotes, '更新说明');
  });

  test('version check failures fail open', () async {
    final service = AppUpdateService(
      isAndroid: true,
      packageInfo: PackageInfo(
        appName: 'DINQ',
        packageName: 'me.dinq.app',
        version: '1.0.0',
        buildNumber: '10',
      ),
      fetchLatestRelease: (platform, channel) => throw StateError('offline'),
    );

    expect(await service.check(), isNull);
  });
}
