import 'package:dinq_app/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('parses a forced update response', () {
    final info = AppUpdateInfo.fromJson({
      'platform': 'android',
      'channel': 'official_apk',
      'update_type': 'force',
      'latest_version': '0.1.2',
      'latest_version_code': 7,
      'minimum_version': '0.1.1',
      'minimum_version_code': 6,
      'release_notes': 'Critical fixes',
      'download_url': 'https://dinq.me/download/android',
    });

    expect(info.isForceUpdate, isTrue);
    expect(info.latestVersionCode, 7);
    expect(info.downloadUrl, 'https://dinq.me/download/android');
  });

  test('rejects unknown update types as no update', () {
    final info = AppUpdateInfo.fromJson({
      'update_type': 'unexpected',
      'latest_version_code': 7,
      'minimum_version_code': 6,
    });

    expect(info.updateType, AppUpdateType.none);
  });

  test('Google Play optional updates do not use the DINQ prompt', () {
    final info = AppUpdateInfo.fromJson({
      'channel': 'google_play',
      'update_type': 'optional',
      'latest_version_code': 7,
      'minimum_version_code': 5,
    });

    expect(info.shouldShowPrompt, isFalse);
  });

  test('sends Android build number and build channel to the backend', () async {
    int? receivedVersionCode;
    String? receivedChannel;
    final service = AppUpdateService(
      isAndroid: true,
      channel: 'official_apk',
      packageInfo: PackageInfo(
        appName: 'DINQ',
        packageName: 'me.dinq.app',
        version: '0.1.0',
        buildNumber: '5',
      ),
      fetchVersion: (versionCode, channel) async {
        receivedVersionCode = versionCode;
        receivedChannel = channel;
        return {'update_type': 'none'};
      },
    );

    await service.check();

    expect(receivedVersionCode, 5);
    expect(receivedChannel, 'official_apk');
  });

  test('version check failures fail open', () async {
    final service = AppUpdateService(
      isAndroid: true,
      packageInfo: PackageInfo(
        appName: 'DINQ',
        packageName: 'me.dinq.app',
        version: '0.1.0',
        buildNumber: '5',
      ),
      fetchVersion: (versionCode, channel) => throw StateError('offline'),
    );

    expect(await service.check(), isNull);
  });
}
