import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeVideoPlayer extends StatefulWidget {
  const YouTubeVideoPlayer({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.isMuted = false,
  });

  final String videoId;
  final double aspectRatio;
  final bool isMuted;

  @override
  State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeController() {
    final embedUrl = Uri.https('www.youtube.com', '/embed/${widget.videoId}', {
      'rel': '0',
      'modestbranding': '1',
      'playsinline': '1',
      'enablejsapi': '1',
      'origin': 'https://dinq.me',
      if (widget.isMuted) 'mute': '1',
    }).toString();
    final html = _buildEmbedHtml(embedUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _loading = true;
                _hasError = false;
              });
              // 设置超时：30秒
              _timeoutTimer?.cancel();
              _timeoutTimer = Timer(const Duration(seconds: 30), () {
                if (mounted && _loading) {
                  setState(() {
                    _loading = false;
                    _hasError = true;
                  });
                }
              });
            }
          },
          onPageFinished: (url) {
            _timeoutTimer?.cancel();
            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = false;
              });
            }
          },
          onWebResourceError: (error) {
            _timeoutTimer?.cancel();

            // 延迟设置错误状态，给页面一些时间完成加载
            if (mounted) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && _loading) {
                  setState(() {
                    _loading = false;
                    _hasError = true;
                  });
                }
              });
            }
          },
        ),
      );

    // 加载 URL
    try {
      _controller.loadHtmlString(html, baseUrl: 'https://dinq.me');
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  String _buildEmbedHtml(String embedUrl) {
    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style>
      html, body {
        margin: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: #000;
      }
      iframe {
        display: block;
        width: 100%;
        height: 100%;
        border: 0;
      }
    </style>
  </head>
  <body>
    <iframe
      src="$embedUrl"
      title="YouTube video player"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen>
    </iframe>
  </body>
</html>
''';
  }

  Widget _buildWebPlaceholder() {
    final thumbnailUrl =
        'https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(thumbnailUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 8),
            Text(
              'Video: ${widget.videoId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // WebView
            kIsWeb
                ? _buildWebPlaceholder()
                : WebViewWidget(controller: _controller),

            // Loading indicator
            if (_loading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),

            // Error state
            if (_hasError)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Failed to load video',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
