import 'package:dinq_app/widgets/profile/profile_share_download.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('share card filenames are safe and stable', () {
    expect(profileShareFilename('Keith Guo'), 'keith-guo-dinq-profile.png');
    expect(profileShareFilename('  '), 'dinq-profile.png');
    expect(profileShareFilename('郭凯斯'), 'dinq-profile.png');
    expect(
      profileShareFilename('../../Sensitive Name'),
      'sensitive-name-dinq-profile.png',
    );
  });
}
