import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest avoids broad media and advertising ID access', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    for (final permission in [
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
      'android.permission.WRITE_MEDIA_IMAGES',
    ]) {
      expect(manifest, isNot(contains(permission)));
    }
    expect(manifest, contains('com.google.android.gms.permission.AD_ID'));
    expect(manifest, contains('tools:node="remove"'));
    expect(manifest, contains('google_analytics_adid_collection_enabled'));
    expect(manifest, contains('android:value="false"'));
  });

  test('Android image selection opts into the system photo picker', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('useAndroidPhotoPicker = true'));
  });
}
