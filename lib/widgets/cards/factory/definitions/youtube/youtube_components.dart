import 'package:flutter/material.dart';

class YouTubeComponents {
  // Extract video ID from embed code or URL
  static String? extractVideoId(String embedCodeOrUrl) {
    if (embedCodeOrUrl.isEmpty) return null;

    // From embed code: <iframe ... src="https://www.youtube.com/embed/VIDEO_ID" ...>
    final iframeMatch = RegExp(r'src="https://www\.youtube\.com/embed/([^"?]+)')
        .firstMatch(embedCodeOrUrl);
    if (iframeMatch != null) return iframeMatch.group(1);

    // Embed URL: https://www.youtube.com/embed/VIDEO_ID
    final embedMatch = RegExp(r'youtube\.com/embed/([^?]+)').firstMatch(embedCodeOrUrl);
    if (embedMatch != null) return embedMatch.group(1);

    // Regular YouTube URL: https://www.youtube.com/watch?v=VIDEO_ID
    final standardMatch = RegExp(r'[?&]v=([^&]+)').firstMatch(embedCodeOrUrl);
    if (standardMatch != null) return standardMatch.group(1);

    // Short YouTube URL: https://youtu.be/VIDEO_ID
    final shortMatch = RegExp(r'youtu\.be/([^?]+)').firstMatch(embedCodeOrUrl);
    if (shortMatch != null) return shortMatch.group(1);

    // Mobile URL: https://m.youtube.com/watch?v=VIDEO_ID
    final mobileMatch = RegExp(r'm\.youtube\.com/watch\?v=([^&]+)').firstMatch(embedCodeOrUrl);
    if (mobileMatch != null) return mobileMatch.group(1);

    // If it's just the video ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(embedCodeOrUrl)) {
      return embedCodeOrUrl;
    }

    return null;
  }

  // Video Embed Component
  static Widget buildVideoEmbed({
    required String? videoId,
    required bool isMuted,
    required VoidCallback onToggleMute,
    required Function(bool) onLoadStateChange,
    bool squareAspectRatio = false,
  }) {
    if (videoId == null || videoId.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              const Text(
                'No video configured',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final embedUrl = 'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1&enablejsapi=1${isMuted ? '&mute=1' : ''}';

    // For web, use html.IFrameElement
    if (squareAspectRatio) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: _buildIframe(embedUrl, isMuted, onToggleMute, onLoadStateChange),
      );
    }

    return _buildIframe(embedUrl, isMuted, onToggleMute, onLoadStateChange);
  }

  static Widget _buildIframe(
    String embedUrl,
    bool isMuted,
    VoidCallback onToggleMute,
    Function(bool) onLoadStateChange,
  ) {
    // For web platform
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // IFrame placeholder - in Flutter web, we need to use platform views
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Loading video...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            // Mute toggle button
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleMute,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

