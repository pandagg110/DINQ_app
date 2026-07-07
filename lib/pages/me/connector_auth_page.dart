import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/common/default_app_bar.dart';

/// 邮箱集成 OAuth 授权页（app 内 WebView）。
///
/// 之前用外部浏览器打开授权，OAuth 回调到 dinq.me/integration（H5）后
/// 浏览器里没有 app 登录态，用户被卡在 H5 登录流程且无法回 App。
/// 改为 app 内 WebView（与 GitHub 登录 github_oauth_signin 同模式）：
/// 导航一旦到达 [callbackUrl] 即拦截并 pop(true)，回原生页刷新已连接状态；
/// 顶部原生返回按钮即「返回 App」兜底入口（pop(false)）。
class ConnectorAuthPage extends StatefulWidget {
  const ConnectorAuthPage({
    super.key,
    required this.authUrl,
    required this.callbackUrl,
    this.title = 'Connect email',
  });

  /// 后端 initiateConnect 返回的 OAuth 授权地址。
  final String authUrl;

  /// 授权完成后的回调地址（命中即视为流程结束）。
  final String callbackUrl;

  final String title;

  @override
  State<ConnectorAuthPage> createState() => _ConnectorAuthPageState();
}

class _ConnectorAuthPageState extends State<ConnectorAuthPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _finished = false;

  // Google OAuth 拒绝内嵌 WebView 的默认 UA（403 disallowed_useragent），
  // 使用标准移动浏览器 UA。
  static final String _userAgent = !kIsWeb && Platform.isAndroid
      ? 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Mobile Safari/537.36'
      : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
            'Mobile/15E148 Safari/604.1';

  bool _isCallback(String url) {
    final cb = widget.callbackUrl;
    return url == cb || url.startsWith('$cb?') || url.startsWith('$cb/');
  }

  void _completeOnce() {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.pop(context, true);
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
              _completeOnce();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          // 兜底：部分平台重定向不触发 onNavigationRequest 时在这里再拦一次。
          onPageStarted: (url) {
            if (_isCallback(url)) _completeOnce();
          },
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
