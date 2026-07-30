import 'dart:convert';
import 'dart:math';

class GitHubOAuthException implements Exception {
  const GitHubOAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GitHubOAuthResult {
  const GitHubOAuthResult.success(this.code) : error = null;
  const GitHubOAuthResult.failure(this.error) : code = null;

  final String? code;
  final String? error;

  bool get isSuccess => code != null && code!.isNotEmpty;
}

class GitHubOAuth {
  const GitHubOAuth._();

  static Uri buildAuthorizationUri({
    required String clientId,
    required Uri redirectUri,
    required String state,
  }) {
    if (clientId.trim().isEmpty) {
      throw const GitHubOAuthException('GitHub login is not configured.');
    }
    if (redirectUri.scheme.toLowerCase() != 'https' ||
        redirectUri.host.isEmpty) {
      throw const GitHubOAuthException(
        'GitHub login callback is not configured securely.',
      );
    }
    return Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      'scope': 'user:email',
      'state': state,
    });
  }

  static String createState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static bool isCallback(Uri candidate, Uri redirectUri) {
    return candidate.scheme.toLowerCase() == redirectUri.scheme.toLowerCase() &&
        candidate.host.toLowerCase() == redirectUri.host.toLowerCase() &&
        candidate.port == redirectUri.port &&
        _normalizedPath(candidate.path) == _normalizedPath(redirectUri.path);
  }

  static bool isAllowedNavigation(Uri candidate, Uri redirectUri) {
    if (isCallback(candidate, redirectUri)) return true;
    return candidate.scheme.toLowerCase() == 'https' &&
        candidate.host.toLowerCase() == 'github.com';
  }

  static String extractAuthorizationCode({
    required Uri callback,
    required Uri redirectUri,
    required String expectedState,
  }) {
    if (!isCallback(callback, redirectUri)) {
      throw const GitHubOAuthException('Unexpected GitHub callback URL.');
    }

    final returnedState = callback.queryParameters['state'];
    if (returnedState == null || returnedState != expectedState) {
      throw const GitHubOAuthException(
        'GitHub login security validation failed.',
      );
    }

    final error = callback.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      throw GitHubOAuthException(
        error == 'access_denied'
            ? 'GitHub login was cancelled.'
            : 'GitHub login failed. Please try again.',
      );
    }

    final code = callback.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const GitHubOAuthException(
        'GitHub did not return an authorization code.',
      );
    }
    return code;
  }

  static String _normalizedPath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }
}
