import 'package:dinq_app/services/auth_service.dart';
import 'package:dinq_app/services/github_oauth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clientId = 'test-client-id';
  final redirectUri = Uri.parse(
    'https://api.dinq.me/auth/oauth/github/callback/app',
  );

  test('clears only the GitHub WebView session before loading OAuth', () async {
    final calls = <String>[];

    await prepareGitHubAccountSelection(
      clearGitHubCookies: () async {
        calls.add('clearGitHubCookies');
      },
      loadAuthorizationPage: () async {
        calls.add('loadAuthorizationPage');
      },
    );

    expect(calls, ['clearGitHubCookies', 'loadAuthorizationPage']);
  });

  test('builds GitHub authorization URL with callback, scope, and state', () {
    final uri = GitHubOAuth.buildAuthorizationUri(
      clientId: clientId,
      redirectUri: redirectUri,
      state: 'csrf-state',
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'github.com');
    expect(uri.path, '/login/oauth/authorize');
    expect(uri.queryParameters['client_id'], clientId);
    expect(uri.queryParameters['redirect_uri'], redirectUri.toString());
    expect(uri.queryParameters['scope'], 'user:email');
    expect(uri.queryParameters['state'], 'csrf-state');
  });

  test('rejects an empty GitHub client ID', () {
    expect(
      () => GitHubOAuth.buildAuthorizationUri(
        clientId: ' ',
        redirectUri: redirectUri,
        state: 'csrf-state',
      ),
      throwsA(isA<GitHubOAuthException>()),
    );
  });

  test('rejects a non-HTTPS callback URL', () {
    expect(
      () => GitHubOAuth.buildAuthorizationUri(
        clientId: clientId,
        redirectUri: Uri.parse(
          'http://api.dinq.me/auth/oauth/github/callback/app',
        ),
        state: 'csrf-state',
      ),
      throwsA(isA<GitHubOAuthException>()),
    );
  });

  test('allows only GitHub HTTPS pages and the configured callback', () {
    expect(
      GitHubOAuth.isAllowedNavigation(
        Uri.parse('https://github.com/login/oauth/authorize'),
        redirectUri,
      ),
      isTrue,
    );
    expect(
      GitHubOAuth.isAllowedNavigation(
        Uri.parse('http://github.com/login'),
        redirectUri,
      ),
      isFalse,
    );
    expect(
      GitHubOAuth.isAllowedNavigation(
        Uri.parse('https://evil.example/login'),
        redirectUri,
      ),
      isFalse,
    );
    expect(
      GitHubOAuth.isAllowedNavigation(
        redirectUri.replace(queryParameters: {'code': 'code'}),
        redirectUri,
      ),
      isTrue,
    );
  });

  test('generates non-repeating OAuth state values', () {
    final first = GitHubOAuth.createState();
    final second = GitHubOAuth.createState();

    expect(first, isNotEmpty);
    expect(second, isNotEmpty);
    expect(second, isNot(first));
  });

  test('extracts code only from the configured callback with matching state', () {
    final callback = redirectUri.replace(
      queryParameters: {'code': 'authorization-code', 'state': 'csrf-state'},
    );

    expect(
      GitHubOAuth.extractAuthorizationCode(
        callback: callback,
        redirectUri: redirectUri,
        expectedState: 'csrf-state',
      ),
      'authorization-code',
    );
  });

  test('rejects callback with mismatched state', () {
    final callback = redirectUri.replace(
      queryParameters: {'code': 'authorization-code', 'state': 'wrong-state'},
    );

    expect(
      () => GitHubOAuth.extractAuthorizationCode(
        callback: callback,
        redirectUri: redirectUri,
        expectedState: 'csrf-state',
      ),
      throwsA(isA<GitHubOAuthException>()),
    );
  });

  test('does not expose GitHub callback details to users', () {
    final callback = redirectUri.replace(
      queryParameters: {
        'error': 'access_denied',
        'error_description': 'The user denied access',
        'state': 'csrf-state',
      },
    );

    expect(
      () => GitHubOAuth.extractAuthorizationCode(
        callback: callback,
        redirectUri: redirectUri,
        expectedState: 'csrf-state',
      ),
      throwsA(isA<GitHubOAuthException>().having(
        (error) => error.message,
        'message',
        'GitHub login was cancelled.',
      )),
    );
  });

  test('rejects a callback without an authorization code', () {
    final callback = redirectUri.replace(
      queryParameters: {'state': 'csrf-state'},
    );

    expect(
      () => GitHubOAuth.extractAuthorizationCode(
        callback: callback,
        redirectUri: redirectUri,
        expectedState: 'csrf-state',
      ),
      throwsA(isA<GitHubOAuthException>()),
    );
  });

  test('accepts an equivalent callback path with a trailing slash', () {
    final callback = Uri.parse(
      'https://api.dinq.me/auth/oauth/github/callback/app/'
      '?code=authorization-code&state=csrf-state',
    );

    expect(
      GitHubOAuth.extractAuthorizationCode(
        callback: callback,
        redirectUri: redirectUri,
        expectedState: 'csrf-state',
      ),
      'authorization-code',
    );
  });

  test('rejects a callback from an unexpected origin', () {
    final callback = Uri.parse(
      'https://evil.example/callback?code=authorization-code&state=csrf-state',
    );

    expect(
      () => GitHubOAuth.extractAuthorizationCode(
        callback: callback,
        redirectUri: redirectUri,
        expectedState: 'csrf-state',
      ),
      throwsA(isA<GitHubOAuthException>()),
    );
  });

  test('sends the authorization code with the exact callback URI', () {
    expect(
      buildThirdPartyLoginPayload(
        provider: 'github',
        idToken: 'authorization-code',
        redirectUri: redirectUri.toString(),
      ),
      {
        'provider': 'github',
        'id_token': 'authorization-code',
        'redirect_uri': redirectUri.toString(),
      },
    );
  });

  test('explains a verified-email provider conflict without exposing internals', () {
    final request = RequestOptions(path: '/auth/oauth/app-login');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 409,
        data: {'message': 'account already exists with another provider'},
      ),
    );

    expect(
      thirdPartyLoginErrorMessage(provider: 'github', error: error),
      'This email is already linked to another sign-in method. Sign in with that method, then connect GitHub in Settings.',
    );
  });
}
