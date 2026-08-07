import 'package:dinq_app/pages/settings/settings_credits_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official Android APK keeps credit purchase controls', () {
    expect(
      shouldShowOfficialApkCreditControls(
        isWeb: false,
        platform: TargetPlatform.android,
        channel: 'official_apk',
      ),
      isTrue,
    );
  });

  test('Google Play build hides credit purchase controls', () {
    expect(
      shouldShowOfficialApkCreditControls(
        isWeb: false,
        platform: TargetPlatform.android,
        channel: 'google_play',
      ),
      isFalse,
    );
  });

  test('iOS App Store build hides credit purchase controls', () {
    expect(
      shouldShowOfficialApkCreditControls(
        isWeb: false,
        platform: TargetPlatform.iOS,
        channel: 'official_apk',
      ),
      isFalse,
    );
  });
}
