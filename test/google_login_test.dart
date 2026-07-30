import 'package:dinq_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Google account selection', () {
    test('clears the cached account before opening Google sign-in', () async {
      final calls = <String>[];

      final account = await selectGoogleAccount<String>(
        clearCachedAccount: () async => calls.add('signOut'),
        signIn: () async {
          calls.add('signIn');
          return 'selected-account';
        },
      );

      expect(calls, ['signOut', 'signIn']);
      expect(account, 'selected-account');
    });
  });

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
