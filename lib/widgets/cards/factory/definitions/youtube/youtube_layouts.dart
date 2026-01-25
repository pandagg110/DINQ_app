import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';
import 'youtube_components.dart';
import 'youtube_video_player.dart';

class YouTubeLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int subscriberCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Youtube.png', size: 40),
          // Bottom Section: Subscriber Info
          Align(
            alignment: Alignment.bottomLeft,
            child: MetricDisplay(
              label: 'Subscribers',
              value: subscriberCount,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required String videoEmbedCode,
    required int subscriberCount,
    required int viewCount,
  }) {
    final videoId = YouTubeComponents.extractVideoId(videoEmbedCode);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Youtube.png', size: 40),
          const SizedBox(height: 12),
          // Spacer to push content to bottom
          const Spacer(),
          // Video Embed Section - Square aspect ratio
          if (videoId != null)
            YouTubeVideoPlayer(
              videoId: videoId,
              aspectRatio: 1.0,
            )
          else
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 48, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 8),
                      Text(
                        'No video configured',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Metrics Section - Vertical Stack
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Subscribers',
                value: subscriberCount,
                align: MetricAlign.start,
              ),
              const SizedBox(height: 16),
              MetricDisplay(
                label: 'Views',
                value: viewCount,
                align: MetricAlign.start,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    required int subscriberCount,
    required int viewCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Youtube.png', size: 40),
          // Bottom Section: Metrics
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Subscribers',
                  value: subscriberCount,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MetricDisplay(
                  label: 'Views',
                  value: viewCount,
                  align: MetricAlign.start,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4x4 Size - Full
  static Widget build4x4Layout({
    required String videoEmbedCode,
    required int subscriberCount,
    required int viewCount,
    required String summary,
  }) {
    final videoId = YouTubeComponents.extractVideoId(videoEmbedCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Youtube.png', size: 40),
          const SizedBox(height: 16),
          // Metrics Section
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Subscribers',
                  value: subscriberCount,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MetricDisplay(
                  label: 'Views',
                  value: viewCount,
                  align: MetricAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Video Embed Section
          if (videoId != null)
            YouTubeVideoPlayer(
              videoId: videoId,
              aspectRatio: 16 / 9,
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 48, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 8),
                      Text(
                        'No video configured',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Summary Section
          if (summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

