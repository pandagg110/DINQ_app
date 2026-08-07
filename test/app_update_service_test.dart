import 'dart:convert';
import 'dart:typed_data';

import 'package:dinq_app/services/api_client.dart';
import 'package:dinq_app/services/app_update_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Map<String, dynamic> _versionPayload({
  String updateType = 'force',
  String channel = 'official_apk',
}) {
  return {
    'platform': 'android',
    'channel': channel,
    'update_type': updateType,
    'latest_version': '1.0.2',
    'latest_version_code': 16,
    'minimum_version': '1.0.2',
    'minimum_version_code': 16,
    'release_notes': '修复已知问题',
    'download_url': 'https://assets.dinq.me/dinq-1.0.2.apk',
  };
}

PackageInfo _packageInfo() => PackageInfo(
  appName: 'DINQ',
  packageName: 'me.dinq.app',
  version: '0.0.1',
  buildNumber: '15',
);

class _VersionEndpointAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({'code': 0, 'data': _versionPayload(), 'message': ''}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('parses force update directly from /app/version response', () {
    final info = AppUpdateInfo.fromJson(_versionPayload());

    expect(info.updateType, AppUpdateType.force);
    expect(info.isForceUpdate, isTrue);
    expect(info.latestVersion, '1.0.2');
    expect(info.latestVersionCode, 16);
    expect(info.minimumVersion, '1.0.2');
    expect(info.minimumVersionCode, 16);
    expect(info.releaseNotes, '修复已知问题');
    expect(info.effectiveDownloadUrl, 'https://assets.dinq.me/dinq-1.0.2.apk');
  });

  test('optional update is visible and skippable for every channel', () {
    final official = AppUpdateInfo.fromJson(
      _versionPayload(updateType: 'optional'),
    );
    final googlePlay = AppUpdateInfo.fromJson(
      _versionPayload(updateType: 'optional', channel: 'google_play'),
    );

    expect(official.shouldShowPrompt, isTrue);
    expect(googlePlay.shouldShowPrompt, isTrue);
  });

  test('none and unknown update types do not show an update prompt', () {
    final none = AppUpdateInfo.fromJson(_versionPayload(updateType: 'none'));
    final unknown = AppUpdateInfo.fromJson(
      _versionPayload(updateType: 'unexpected'),
    );

    expect(none.updateType, AppUpdateType.none);
    expect(none.shouldShowPrompt, isFalse);
    expect(unknown.updateType, AppUpdateType.none);
  });

  test('missing download URL falls back to the stable APK endpoint', () {
    final info = AppUpdateInfo.fromJson({
      ..._versionPayload(),
      'download_url': '',
    });

    expect(info.effectiveDownloadUrl, androidApkDownloadUrl);
  });

  test(
    'version check sends platform, channel, and installed version code',
    () async {
      final service = AppUpdateService(
        isAndroid: true,
        channel: 'official_apk',
        packageInfo: _packageInfo(),
        fetchVersion: (platform, channel, versionCode) async {
          expect(platform, 'android');
          expect(channel, 'official_apk');
          expect(versionCode, 15);
          return _versionPayload();
        },
      );

      final info = await service.check();

      expect(info?.updateType, AppUpdateType.force);
    },
  );

  test('runtime request uses only /app/version with required query', () async {
    final adapter = _VersionEndpointAdapter();
    ApiClient.instance.dio.httpClientAdapter = adapter;
    final service = AppUpdateService(
      isAndroid: true,
      channel: 'official_apk',
      packageInfo: _packageInfo(),
    );

    final info = await service.check();

    expect(info?.updateType, AppUpdateType.force);
    expect(adapter.request?.path, '/app/version');
    expect(adapter.request?.queryParameters, {
      'platform': 'android',
      'channel': 'official_apk',
      'version_code': 15,
    });
  });

  test('version check failures fail open', () async {
    final service = AppUpdateService(
      isAndroid: true,
      packageInfo: _packageInfo(),
      fetchVersion: (_, _, _) => throw StateError('offline'),
    );

    expect(await service.check(), isNull);
  });
}
