import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final class AppleSignInException implements Exception {
  const AppleSignInException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AppleSignInRequest {
  const AppleSignInRequest({required this.rawNonce, required this.hashedNonce});

  final String rawNonce;
  final String hashedNonce;
}

final class AppleSignInCredentialData {
  const AppleSignInCredentialData._({
    required this.rawNonce,
    required this.identityToken,
    required this.authorizationCode,
    this.givenName,
    this.familyName,
  });

  factory AppleSignInCredentialData.fromValues({
    required String rawNonce,
    required String? identityToken,
    required String? authorizationCode,
    String? givenName,
    String? familyName,
  }) {
    final normalizedNonce = rawNonce.trim();
    final normalizedIdentityToken = identityToken?.trim() ?? '';
    final normalizedAuthorizationCode = authorizationCode?.trim() ?? '';
    if (normalizedNonce.isEmpty ||
        normalizedIdentityToken.isEmpty ||
        normalizedAuthorizationCode.isEmpty) {
      throw const AppleSignInException(
        'Apple did not return valid login credentials. Please try again.',
      );
    }
    return AppleSignInCredentialData._(
      rawNonce: normalizedNonce,
      identityToken: normalizedIdentityToken,
      authorizationCode: normalizedAuthorizationCode,
      givenName: _optionalValue(givenName),
      familyName: _optionalValue(familyName),
    );
  }

  final String rawNonce;
  final String identityToken;
  final String authorizationCode;
  final String? givenName;
  final String? familyName;
}

final class AppleIdentityTokenDiagnostics {
  const AppleIdentityTokenDiagnostics({
    required this.emailPresent,
    required this.emailVerified,
    required this.emailVerifiedType,
    required this.noncePresent,
    required this.audience,
  });

  final bool emailPresent;
  final Object? emailVerified;
  final String emailVerifiedType;
  final bool noncePresent;
  final String? audience;

  @override
  String toString() =>
      'emailPresent=$emailPresent, emailVerified=$emailVerified, '
      'emailVerifiedType=$emailVerifiedType, noncePresent=$noncePresent, '
      'audience=$audience';
}

String? _optionalValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

final class AppleSignInService {
  const AppleSignInService._();

  static const _nonceCharacters =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

  static String generateRawNonce({int length = 32}) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'must be greater than zero');
    }
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => _nonceCharacters[random.nextInt(_nonceCharacters.length)],
    ).join();
  }

  static AppleSignInRequest prepareRequest(String rawNonce) {
    final normalized = rawNonce.trim();
    if (normalized.isEmpty) {
      throw const AppleSignInException('Unable to start Apple login.');
    }
    return AppleSignInRequest(
      rawNonce: normalized,
      hashedNonce: sha256.convert(utf8.encode(normalized)).toString(),
    );
  }

  static AppleIdentityTokenDiagnostics inspectIdentityToken(String token) {
    final segments = token.split('.');
    if (segments.length != 3) {
      throw const AppleSignInException(
        'Apple returned an invalid identity token.',
      );
    }
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      if (payload is! Map) {
        throw const FormatException('JWT payload is not an object');
      }
      final email = payload['email'];
      final verified = payload['email_verified'];
      return AppleIdentityTokenDiagnostics(
        emailPresent: email is String && email.trim().isNotEmpty,
        emailVerified: verified,
        emailVerifiedType: verified?.runtimeType.toString() ?? 'null',
        noncePresent: payload['nonce'] is String,
        audience: payload['aud']?.toString(),
      );
    } catch (_) {
      throw const AppleSignInException(
        'Apple returned an invalid identity token.',
      );
    }
  }

  static Future<AppleSignInCredentialData?> authorize() async {
    final request = prepareRequest(generateRawNonce());
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: request.hashedNonce,
      );
      return AppleSignInCredentialData.fromValues(
        rawNonce: request.rawNonce,
        identityToken: credential.identityToken,
        authorizationCode: credential.authorizationCode,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      throw const AppleSignInException('Apple login failed. Please try again.');
    }
  }
}
