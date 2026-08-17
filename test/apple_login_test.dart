import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dinq_app/services/auth_service.dart';
import 'package:dinq_app/services/apple_sign_in_service.dart';

void main() {
  group('Apple login payload', () {
    test('hashes the nonce for Apple and keeps raw nonce for the backend', () {
      const rawNonce = 'test-raw-nonce';

      final request = AppleSignInService.prepareRequest(rawNonce);

      expect(request.rawNonce, rawNonce);
      expect(request.hashedNonce, isNot(rawNonce));
      expect(request.hashedNonce.length, 64);
      expect(
        request.hashedNonce,
        '8c3e0ad9731a649be51afa37753e4db2ab367707b3f92e183cce77e688b7722e',
      );
    });

    test('builds the backend payload with raw nonce and optional name', () {
      final payload = buildThirdPartyLoginPayload(
        provider: 'apple',
        idToken: 'identity-token',
        authorizationCode: 'authorization-code',
        nonce: 'raw',
        givenName: 'Ada',
        familyName: 'Lovelace',
      );

      expect(payload, {
        'provider': 'apple',
        'id_token': 'identity-token',
        'authorization_code': 'authorization-code',
        'nonce': 'raw',
        'given_name': 'Ada',
        'family_name': 'Lovelace',
      });
    });

    test('does not send empty optional names', () {
      final payload = buildThirdPartyLoginPayload(
        provider: 'apple',
        idToken: 'identity-token',
        authorizationCode: 'authorization-code',
        nonce: 'raw',
        givenName: ' ',
        familyName: null,
      );

      expect(payload.containsKey('given_name'), isFalse);
      expect(payload.containsKey('family_name'), isFalse);
    });

    test('rejects missing Apple identity token or authorization code', () {
      expect(
        () => AppleSignInCredentialData.fromValues(
          rawNonce: 'raw',
          identityToken: null,
          authorizationCode: 'authorization-code',
        ),
        throwsA(isA<AppleSignInException>()),
      );
      expect(
        () => AppleSignInCredentialData.fromValues(
          rawNonce: 'raw',
          identityToken: 'identity-token',
          authorizationCode: ' ',
        ),
        throwsA(isA<AppleSignInException>()),
      );
    });

    test('inspects Apple identity token claims without exposing the email', () {
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'aud': 'me.dinq.app',
                'email': 'private@example.com',
                'email_verified': 'true',
                'nonce': 'hashed-nonce',
              }),
            ),
          )
          .replaceAll('=', '');

      final diagnostics = AppleSignInService.inspectIdentityToken(
        'header.$payload.signature',
      );

      expect(diagnostics.emailPresent, isTrue);
      expect(diagnostics.emailVerified, 'true');
      expect(diagnostics.emailVerifiedType, 'String');
      expect(diagnostics.noncePresent, isTrue);
      expect(diagnostics.audience, 'me.dinq.app');
      expect(diagnostics.toString(), isNot(contains('private@example.com')));
    });
  });
}
