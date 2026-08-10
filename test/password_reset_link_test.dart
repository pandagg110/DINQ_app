import 'package:dinq_app/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password reset email points to the deployed callback route', () {
    expect(passwordResetCallbackUrl, '$appUrl/reset/callback');
    expect(Uri.parse(passwordResetCallbackUrl).path, '/reset/callback');
  });
}
