import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/common/default_app_bar.dart';

/// Social Verification OAuth 授权页（应用内 WebView）。
///
/// 打开后端返回的授权 URL；用户授权后跳到
/// `https://dinq.me/social-callback?code=&state=`，拦截该 URL，
/// 取出 code / state（或 error）后 pop 回调用方，由调用方调 link 接口。
class SocialOAuthPage extends StatefulWidget {
  const SocialOAuthPage({
    super.key,
    required this.authUrl,
    this.title = 'Link account',
  });

  final String authUrl;
  final String title;

  @override
  State<SocialOAuthPage> createState() => _SocialOAuthPageState();
}

/// WebView 拦回调后回传的结果。
class SocialOAuthResult {
  const SocialOAuthResult({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
  });

  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  bool get isSuccess =>
      (error == null || error!.isEmpty) &&
      code != null &&
      code!.isNotEmpty &&
      state != null &&
      state!.isNotEmpty;
}

class _SocialOAuthPageState extends State<SocialOAuthPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _finished = false;

  // LinkedIn / X 可能拒绝内嵌 WebView 默认 UA，使用标准移动浏览器 UA。
  static final String _userAgent = !kIsWeb && Platform.isAndroid
      ? 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Mobile Safari/537.36'
      : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
            'Mobile/15E148 Safari/604.1';

  bool _isSocialCallback(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path.contains('social-callback');
    } catch (_) {
      return url.contains('social-callback');
    }
  }

  void _completeOnce(SocialOAuthResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.pop(context, result);
  }

  void _handleCallbackUrl(String url) {
    if (!_isSocialCallback(url)) return;
    try {
      final uri = Uri.parse(url);
      _completeOnce(
        SocialOAuthResult(
          code: uri.queryParameters['code'],
          state: uri.queryParameters['state'],
          error: uri.queryParameters['error'],
          errorDescription: uri.queryParameters['error_description'],
        ),
      );
    } catch (_) {
      _completeOnce(
        const SocialOAuthResult(error: 'invalid_callback'),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p / 100.0);
          },
          onNavigationRequest: (request) {
            if (_isSocialCallback(request.url)) {
              _handleCallbackUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          // 兜底：部分平台重定向不触发 onNavigationRequest 时在这里再拦一次。
          onPageStarted: _handleCallbackUrl,
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DefaultAppBar(
        context,
        backgroundColor: Colors.white,
        titleString: widget.title,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              value: _progress >= 1.0 ? 0 : _progress,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF171717),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
