import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class TikTokWidget extends StatelessWidget {
  const TikTokWidget({
    super.key,
    required this.card,
    required this.size,
    required this.editable,
  });

  final dynamic card;
  final String size;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata as Map<String, dynamic>;
    final username = metadata['username']?.toString() ?? '';
    final name = metadata['name']?.toString() ?? '';
    final avatar = metadata['avatar']?.toString() ?? '';
    final followerCount = _toInt(metadata['followerCount']);
    final likeCount = _toInt(metadata['likeCount']);
    final topVideo = metadata['topVideo'] is Map
        ? Map<String, dynamic>.from(metadata['topVideo'] as Map)
        : null;
    final profileUrl = (metadata['url']?.toString().isNotEmpty ?? false)
        ? metadata['url'].toString()
        : 'https://www.tiktok.com/@$username';
    final videoUrl =
        topVideo?['url']?.toString() ?? metadata['url']?.toString() ?? '';

    switch (size) {
      case '2x2':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _TikTokIcon(),
              MetricDisplay(label: 'Followers', value: followerCount),
            ],
          ),
        );
      case '2x4':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TikTokIcon(),
              const Spacer(),
              AspectRatio(
                aspectRatio: 1,
                child: _TikTokVideoBlock(
                  videoUrl: videoUrl,
                  topVideo: topVideo,
                ),
              ),
              const SizedBox(height: 12),
              MetricDisplay(label: 'Followers', value: followerCount),
              const SizedBox(height: 16),
              MetricDisplay(label: 'Likes', value: likeCount),
            ],
          ),
        );
      case '4x2':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _TikTokIcon(),
              Row(
                children: [
                  Expanded(
                    child: MetricDisplay(
                      label: 'Followers',
                      value: followerCount,
                    ),
                  ),
                  Expanded(
                    child: MetricDisplay(label: 'Likes', value: likeCount),
                  ),
                  Expanded(
                    child: MetricDisplay(
                      label: 'Views',
                      value: _toInt(topVideo?['views']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case '4x4':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TikTokIcon(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricDisplay(
                      label: 'Followers',
                      value: followerCount,
                    ),
                  ),
                  Expanded(
                    child: MetricDisplay(label: 'Likes', value: likeCount),
                  ),
                  Expanded(
                    child: MetricDisplay(
                      label: 'Views',
                      value: _toInt(topVideo?['views']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _TikTokVideoBlock(
                  videoUrl: videoUrl,
                  topVideo: topVideo,
                ),
              ),
              const SizedBox(height: 12),
              _ProfileFooter(
                username: username,
                name: name,
                avatar: avatar,
                profileUrl: profileUrl,
                topVideoTitle: topVideo?['title']?.toString() ?? '',
              ),
            ],
          ),
        );
      default:
        return const Center(child: Text('TikTok'));
    }
  }
}

class _TikTokIcon extends StatelessWidget {
  const _TikTokIcon();

  @override
  Widget build(BuildContext context) {
    return const AssetIcon(asset: 'icons/social-icons/Tiktok.svg', size: 40);
  }
}

class _TikTokVideoBlock extends StatelessWidget {
  const _TikTokVideoBlock({required this.videoUrl, required this.topVideo});

  final String videoUrl;
  final Map<String, dynamic>? topVideo;

  @override
  Widget build(BuildContext context) {
    final videoId = _extractTikTokVideoId(videoUrl);
    if (videoId != null) {
      return _TikTokPlayer(videoId: videoId, views: _toInt(topVideo?['views']));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Opacity(
              opacity: 0.25,
              child: AssetIcon(
                asset: 'icons/social-icons/Tiktok.svg',
                size: 48,
              ),
            ),
          ),
          if ((topVideo?['title']?.toString().isNotEmpty ?? false))
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                topVideo!['title'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TikTokPlayer extends StatefulWidget {
  const _TikTokPlayer({required this.videoId, required this.views});

  final String videoId;
  final int views;

  @override
  State<_TikTokPlayer> createState() => _TikTokPlayerState();
}

class _TikTokPlayerState extends State<_TikTokPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _hasError = false;
            });
            _timeoutTimer?.cancel();
            _timeoutTimer = Timer(const Duration(seconds: 20), () {
              if (!mounted || !_loading) return;
              setState(() {
                _loading = false;
                _hasError = true;
              });
            });
          },
          onPageFinished: (_) {
            _timeoutTimer?.cancel();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = false;
            });
          },
          onWebResourceError: (_) {
            _timeoutTimer?.cancel();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.tiktok.com/player/v1/${widget.videoId}'),
      );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (kIsWeb || _hasError)
            const _VideoFallback()
          else
            WebViewWidget(controller: _controller),
          if (_loading)
            Container(
              color: const Color(0xFFE5E7EB),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (widget.views > 0)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Views ${formatCount(widget.views)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: AssetIcon(asset: 'icons/social-icons/Tiktok.svg', size: 48),
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.username,
    required this.name,
    required this.avatar,
    required this.profileUrl,
    required this.topVideoTitle,
  });

  final String username;
  final String name;
  final String avatar;
  final String profileUrl;
  final String topVideoTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: topVideoTitle.isNotEmpty
          ? Text(
              topVideoTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            )
          : Row(
              children: [
                ClipOval(
                  child: avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name.isNotEmpty ? name : username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(width: 32, height: 32, color: const Color(0xFFE5E7EB));
  }
}

String? _extractTikTokVideoId(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) return null;
  if (RegExp(r'^\d{8,}$').hasMatch(value)) return value;

  final patterns = [
    RegExp(r'/video/(\d{8,})', caseSensitive: false),
    RegExp(r'/v/(\d{8,})', caseSensitive: false),
    RegExp(r'[?&]share_item_id=(\d{8,})', caseSensitive: false),
    RegExp(r'[?&]item_id=(\d{8,})', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(value);
    if (match != null) return match.group(1);
  }

  final uri = Uri.tryParse(value);
  final queryId =
      uri?.queryParameters['share_item_id'] ?? uri?.queryParameters['item_id'];
  if (queryId != null && RegExp(r'^\d{8,}$').hasMatch(queryId)) return queryId;

  return null;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
