import 'dart:async';

import 'package:dinq_app/services/oauth_login_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'generic login success cleanup errors are not reported as authentication errors',
    () async {
      final authenticationErrors = <Object>[];

      final authenticated = await runLoginAttempt(
        authenticate: () async {},
        onAuthenticated: () async {
          throw StateError('navigation failed');
        },
        onAuthenticationFailed: authenticationErrors.add,
      );

      expect(authenticated, isTrue);
      expect(authenticationErrors, isEmpty);
    },
  );

  test(
    'post-login navigation errors are not reported as authentication errors',
    () async {
      final authenticationErrors = <Object>[];

      final authenticated = await runOAuthLoginAttempt(
        authenticate: () async => true,
        onAuthenticated: () async {
          throw StateError('navigation failed');
        },
        onAuthenticationFailed: authenticationErrors.add,
      );

      expect(authenticated, isTrue);
      expect(authenticationErrors, isEmpty);
    },
  );

  test('authentication errors use the login failure path', () async {
    final authenticationErrors = <Object>[];

    final authenticated = await runOAuthLoginAttempt(
      authenticate: () async => throw StateError('invalid credential'),
      onAuthenticated: () async {},
      onAuthenticationFailed: authenticationErrors.add,
    );

    expect(authenticated, isFalse);
    expect(authenticationErrors.single, isA<StateError>());
  });

  test(
    'cancelled account selection does not run success or failure callbacks',
    () async {
      var successCalled = false;
      var failureCalled = false;

      final authenticated = await runOAuthLoginAttempt(
        authenticate: () async => false,
        onAuthenticated: () async => successCalled = true,
        onAuthenticationFailed: (_) async => failureCalled = true,
      );

      expect(authenticated, isFalse);
      expect(successCalled, isFalse);
      expect(failureCalled, isFalse);
    },
  );

  test(
    'attempt guard ignores a second login while the first is active',
    () async {
      final guard = OAuthLoginAttemptGuard();
      final firstAttemptCompleter = Completer<void>();
      var invocationCount = 0;

      final firstAttempt = guard.run(() async {
        invocationCount++;
        await firstAttemptCompleter.future;
      });
      final secondAttempt = await guard.run(() async {
        invocationCount++;
      });

      expect(secondAttempt, isFalse);
      expect(invocationCount, 1);

      firstAttemptCompleter.complete();
      expect(await firstAttempt, isTrue);
      expect(
        await guard.run(() async {
          invocationCount++;
        }),
        isTrue,
      );
      expect(invocationCount, 2);
    },
  );
}
