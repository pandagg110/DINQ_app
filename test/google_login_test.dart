import 'package:dinq_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Google login token validation', () {
    test('accepts a non-empty Google ID token', () {
      expect(requireGoogleIdToken('  signed-id-token  '), 'signed-id-token');
    });

    test('rejects a build that cannot obtain a Google ID token', () {
      for (final token in <String?>[null, '', '   ']) {
        expect(
          () => requireGoogleIdToken(token),
          throwsA(
            isA<GoogleLoginException>().having(
              (error) => error.message,
              'message',
              'Google login is not configured for this app build.',
            ),
          ),
        );
      }
    });
  });

  group('Google login error messages', () {
    test('does not expose the raw Dio exception to users', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/auth/oauth/app-login'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/oauth/app-login'),
          statusCode: 400,
          data: {'message': 'provider and id_token are required'},
        ),
      );

      expect(
        googleLoginErrorMessage(error),
        'provider and id_token are required',
      );
      expect(googleLoginErrorMessage(error), isNot(contains('DioException')));
    });
  });
}
