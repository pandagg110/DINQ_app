import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import '../card_definition.dart';

class IframeCardDefinition extends CardDefinition {
  @override
  String get type => 'IFRAME';

  @override
  String get icon => '/icons/iframe.png';

  @override
  String get name => 'Iframe';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
      );

  @override
  Widget render(CardRenderParams params) {
    return _IframeCardWidget(
      card: params.card,
      editable: params.editable,
    );
  }
}

class _IframeCardWidget extends StatefulWidget {
  const _IframeCardWidget({
    required this.card,
    required this.editable,
  });

  final dynamic card;
  final bool editable;

  @override
  State<_IframeCardWidget> createState() => _IframeCardWidgetState();
}

class _IframeCardWidgetState extends State<_IframeCardWidget> {
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
    final rawUrl = widget.card.data.metadata['url']?.toString() ?? '';
    
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
                _hasError = false; // 清除之前的错误状态
              });
            }
          },
          onWebResourceError: (error) {
            _timeoutTimer?.cancel();
            
            // 某些错误可能是暂时的，不立即显示错误
            // 例如 timeout 错误，如果页面最终加载成功，onPageFinished 会清除错误状态
            if (mounted) {
              // 延迟设置错误状态，给页面一些时间完成加载
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
    if (rawUrl.isNotEmpty) {
      _loadUrl(rawUrl);
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _loadUrl(String rawUrl) {
    final embedUrl = _convertYouTubeToEmbed(rawUrl);
    
    
    try {
      // 统一使用 loadRequest
      _controller.loadRequest(Uri.parse(embedUrl));
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  String _convertYouTubeToEmbed(String url) {
    try {
      final uri = Uri.parse(url);
      
      // YouTube watch URL: https://www.youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.path == '/watch') {
        final videoId = uri.queryParameters['v'];
        if (videoId != null && videoId.isNotEmpty) {
          return 'https://www.youtube.com/embed/$videoId';
        }
      }
      
      // YouTube short URL: https://youtu.be/VIDEO_ID
      if (uri.host == 'youtu.be') {
        final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        if (videoId.isNotEmpty) {
          return 'https://www.youtube.com/embed/$videoId';
        }
      }
      
      return url;
    } catch (e) {
      return url;
    }
  }

  String _getWebsiteName(String url) {
    try {
      final uri = Uri.parse(url);
      var hostname = uri.host;
      
      // Remove www. prefix
      if (hostname.startsWith('www.')) {
        hostname = hostname.substring(4);
      }
      
      // Extract main domain name (e.g., youtube.com → youtube)
      final parts = hostname.split('.');
      final domainName = parts.isNotEmpty ? parts[0] : hostname;
      
      // Capitalize first letter
      if (domainName.isNotEmpty) {
        return domainName[0].toUpperCase() + domainName.substring(1);
      }
      
      return 'Embedded content';
    } catch (e) {
      return 'Embedded content';
    }
  }


  Widget _buildWebPlaceholder(String url) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.web, size: 48, color: Color(0xFF6B7280)),
          const SizedBox(height: 8),
          const Text(
            'WebView not supported on Web platform',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            url,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = widget.card.data.metadata['url']?.toString() ?? '';
    final url = rawUrl.isNotEmpty ? _convertYouTubeToEmbed(rawUrl) : '';

    if (url.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFF3F4F6),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🌐', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text(
                'No URL configured',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF3F4F6),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // WebView
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: Colors.transparent,
              child: IgnorePointer(
                ignoring: widget.editable && _loading,
                child: kIsWeb
                    ? _buildWebPlaceholder(url)
                    : WebViewWidget(controller: _controller),
              ),
            ),
          ),

          // Loading indicator
          if (_loading)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFE5E7EB),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Error state
          if (_hasError)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFF3F4F6),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to load',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This page may not allow embedding',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _loading = true;
                        });
                        final rawUrl = widget.card.data.metadata['url']?.toString() ?? '';
                        if (rawUrl.isNotEmpty) {
                          _loadUrl(rawUrl);
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
