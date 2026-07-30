import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/github_oauth.dart';
import '../../widgets/common/default_app_bar.dart';

class GitHubOAuthPage extends StatefulWidget {
  const GitHubOAuthPage({
    super.key,
    required this.clientId,
    required this.redirectUri,
  });

  final String clientId;
  final Uri redirectUri;

  @override
  State<GitHubOAuthPage> createState() => _GitHubOAuthPageState();
}

class _GitHubOAuthPageState extends State<GitHubOAuthPage> {
  late final WebViewController _controller;
  late final String _state;
  double _progress = 0;
  bool _finished = false;
  bool _authorizationStarted = false;

  static final String _userAgent = !kIsWeb && Platform.isAndroid
      ? 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Mobile Safari/537.36'
      : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
            'Mobile/15E148 Safari/604.1';

  void _complete(GitHubOAuthResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(result);
  }

  NavigationDecision _handleNavigation(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _complete(
        const GitHubOAuthResult.failure(
          'Unable to open GitHub login. Please try again.',
        ),
      );
      return NavigationDecision.prevent;
    }
    if (!GitHubOAuth.isCallback(uri, widget.redirectUri)) {
      if (GitHubOAuth.isAllowedNavigation(uri, widget.redirectUri)) {
        return NavigationDecision.navigate;
      }
      _complete(
        const GitHubOAuthResult.failure(
          'GitHub login cannot open this page.',
        ),
      );
      return NavigationDecision.prevent;
    }

    try {
      final code = GitHubOAuth.extractAuthorizationCode(
        callback: uri,
        redirectUri: widget.redirectUri,
        expectedState: _state,
      );
      _complete(GitHubOAuthResult.success(code));
    } on GitHubOAuthException catch (error) {
      _complete(GitHubOAuthResult.failure(error.message));
    }
    return NavigationDecision.prevent;
  }

  Future<void> _prepareAuthorizationPage(Uri authorizationUri) async {
    try {
      await prepareGitHubAccountSelection(
        clearGitHubCookies: clearGitHubWebViewCookies,
        loadAuthorizationPage: () async {
          if (!mounted) return;
          setState(() => _authorizationStarted = true);
          await _controller.loadRequest(authorizationUri);
        },
      );
    } catch (_) {
      _complete(
        const GitHubOAuthResult.failure(
          'Unable to open GitHub login. Please try again.',
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _state = GitHubOAuth.createState();
    final authorizationUri = GitHubOAuth.buildAuthorizationUri(
      clientId: widget.clientId,
      redirectUri: widget.redirectUri,
      state: _state,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100.0);
          },
          onNavigationRequest: (request) => _handleNavigation(request.url),
          onPageStarted: _handleNavigation,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _complete(
                const GitHubOAuthResult.failure(
                  'Unable to open GitHub login. Please try again.',
                ),
              );
            }
          },
        ),
      );
    unawaited(_prepareAuthorizationPage(authorizationUri));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DefaultAppBar(
        context,
        backgroundColor: Colors.white,
        titleString: 'Continue with GitHub',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              value: _progress >= 1 ? 0 : _progress,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF171717),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _authorizationStarted
            ? WebViewWidget(controller: _controller)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
