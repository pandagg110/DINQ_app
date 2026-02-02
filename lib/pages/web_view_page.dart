import 'dart:io';

import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/common/default_app_bar.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String? navTitle;
  final bool showAppBar;
  final bool showDefineBar;

  const WebViewPage({
    super.key,
    required this.url,
    this.navTitle,
    this.showAppBar = true,
    this.showDefineBar = false,
  });

  @override
  State<WebViewPage> createState() => WebViewState<WebViewPage>();
}

class WebViewState<T extends WebViewPage> extends State<T> with WidgetsBindingObserver {
  double _lineProgress = 0.0;

  late final WebViewController _webViewController = WebViewController();

  late final WebViewWidget _webView = WebViewWidget(controller: _webViewController);

  bool _isNetworkErr = false;

  late String _urlString;
  late String? _navTitle;
  late bool _showAppBar;

  @override
  void initState() {
    super.initState();

    _urlString = widget.url;
    _navTitle = widget.navTitle;
    _showAppBar = widget.showAppBar;

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _handleUrl();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleUrl() {
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.addJavaScriptChannel(
      "jsHandleOpenWebVC",
      onMessageReceived: (message) {
        final url = Uri.encodeComponent(message.message);
        context.push('/webview?url=$url&showAppBar=false');
      },
    );
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          if (mounted) {
            setState(() {
              _lineProgress = progress / 100.0;
            });
          }
        },
        onPageFinished: (String s) {},
        onPageStarted: (String url) {
          if (mounted) {
            setState(() {
              _isNetworkErr = false;
            });
          }
        },
        onWebResourceError: (WebResourceError error) {
          if ((error.errorCode == -2 && Platform.isAndroid) ||
              (error.errorCode == -1009 && Platform.isIOS)) {
            if (mounted) {
              setState(() {
                _isNetworkErr = true;
              });
            }
          }
        },
      ),
    );

    _webViewController.loadRequest(Uri.parse(_urlString));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildNavNar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _webView,
            // Visibility(
            //   visible: _isNetworkErr,
            //   child: Container(
            //     color: Colors.white,
            //     child: EmptyView(
            //       showRetry: true,
            //       onRetryCallback: () {
            //         _webViewController.loadRequest(Uri.parse(_urlString));
            //       },
            //     ),
            //   ),
            // ),
            if (!_showAppBar) _buildProgressBar(_lineProgress),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProgressBar(double progress) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(2.0),
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          value: progress == 1.0 ? 0 : progress,
          valueColor: AlwaysStoppedAnimation<Color>(ColorUtil.mainColor),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildNavNar() {
    if (_showAppBar) {
      return DefaultAppBar(
        context,
        backgroundColor: Colors.white,
        titleString: _navTitle ?? "",
        centerTitle: true,
        bottom: _buildProgressBar(_lineProgress),
      );
    } else {
      return null;
    }
  }
}
