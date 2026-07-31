import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/common/default_app_bar.dart';

/// 第三方授权页（应用内 WebView），供 Social Verification 与账号绑定共用。
///
/// 打开后端返回的授权 URL；用户授权后会跳到 `https://dinq.me/<callbackPath>?code=&state=`，
/// 拦截该 URL，取出 code / state（或 error）后 pop 回调用方，由调用方调对应的 link 接口。
class OAuthWebViewPage extends StatefulWidget {
  const OAuthWebViewPage({
    super.key,
    required this.authUrl,
    required this.callbackPath,
    this.title = 'Authorize',
    this.prepare,
  });

  final String authUrl;

  /// 回调地址的路径片段，如 `social-callback` / `account-callback`。
  final String callbackPath;

  final String title;

  /// 加载授权页前的准备工作，如清除平台 Cookie，让用户可以重新选择账号。
  final Future<void> Function()? prepare;

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

/// WebView 拦回调后回传的结果。
class OAuthCallbackResult {
  const OAuthCallbackResult({
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

  String get failureMessage =>
      errorDescription ?? error ?? 'Authorization was cancelled or failed';
}

class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _finished = false;
  bool _loadStarted = false;

  // 部分平台（LinkedIn / X / Google）拒绝内嵌 WebView 默认 UA，使用标准移动浏览器 UA。
  static final String _userAgent = !kIsWeb && Platform.isAndroid
      ? 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Mobile Safari/537.36'
      : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
            'Mobile/15E148 Safari/604.1';

  bool _isCallback(String url) {
    try {
      return Uri.parse(url).path.contains(widget.callbackPath);
    } catch (_) {
      return url.contains(widget.callbackPath);
    }
  }

  void _completeOnce(OAuthCallbackResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.pop(context, result);
  }

  void _handleCallbackUrl(String url) {
    if (!_isCallback(url)) return;
    try {
      final uri = Uri.parse(url);
      _completeOnce(
        OAuthCallbackResult(
          code: uri.queryParameters['code'],
          state: uri.queryParameters['state'],
          error: uri.queryParameters['error'],
          errorDescription: uri.queryParameters['error_description'],
        ),
      );
    } catch (_) {
      _completeOnce(const OAuthCallbackResult(error: 'invalid_callback'));
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
            if (_isCallback(request.url)) {
              _handleCallbackUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          // 兜底：部分平台重定向不触发 onNavigationRequest 时在这里再拦一次。
          onPageStarted: _handleCallbackUrl,
        ),
      );
    unawaited(_loadAuthorizationPage());
  }

  Future<void> _loadAuthorizationPage() async {
    final prepare = widget.prepare;
    if (prepare != null) {
      // 清 Cookie 失败只会让平台沿用上次的登录态，不该因此中断授权。
      try {
        await prepare();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _loadStarted = true);
    await _controller.loadRequest(Uri.parse(widget.authUrl));
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
        child: _loadStarted
            ? WebViewWidget(controller: _controller)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
