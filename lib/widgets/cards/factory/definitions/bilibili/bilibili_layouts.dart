import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class BilibiliLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int followers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Bilibili.svg', size: 40),
          // Bottom Section: Followers
          MetricDisplay(
            label: 'Followers',
            value: followers,
            align: MetricAlign.start,
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required int followers,
    required int archiveView,
    Map<String, dynamic>? firstWork,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Bilibili.svg', size: 40),
          const SizedBox(height: 12),
          // Spacer
          const Spacer(),
          // Video Cover Section - Square aspect ratio
          if (firstWork != null) ...[
            AspectRatio(
              aspectRatio: 1.0,
              child: InkWell(
                onTap: () async {
                  final bvid = firstWork['bvid'] as String?;
                  if (bvid != null && bvid.isNotEmpty) {
                    final uri = Uri.parse('https://www.bilibili.com/video/$bvid/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstWork['cover'] as String? ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Icon(Icons.video_library, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    // Video title overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          firstWork['title'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Play count badge
                    if (firstWork['play'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _formatCount((firstWork['play'] as num?)?.toInt() ?? 0),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No video',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Metrics Section - Vertical Stack
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Followers',
                value: followers,
                align: MetricAlign.start,
              ),
              const SizedBox(height: 16),
              MetricDisplay(
                label: 'Views',
                value: archiveView,
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
    required int followers,
    required int archiveView,
    required int likes,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Bilibili.svg', size: 40),
          // Bottom Section: Metrics - 3 columns
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Followers',
                  value: followers,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricDisplay(
                  label: 'Views',
                  value: archiveView,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricDisplay(
                  label: 'Likes',
                  value: likes,
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
    required int followers,
    required int archiveView,
    required String bio,
    Map<String, dynamic>? firstWork,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Bilibili.svg', size: 40),
          const SizedBox(height: 16),
          // Metrics Section - 2 columns
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Followers',
                  value: followers,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MetricDisplay(
                  label: 'Views',
                  value: archiveView,
                  align: MetricAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Video Cover Section - Takes most space
          if (firstWork != null) ...[
            Expanded(
              child: InkWell(
                onTap: () async {
                  final bvid = firstWork['bvid'] as String?;
                  if (bvid != null && bvid.isNotEmpty) {
                    final uri = Uri.parse('https://www.bilibili.com/video/$bvid/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstWork['cover'] as String? ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Icon(Icons.video_library, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    // Video title overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          firstWork['title'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Bio Section at bottom
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bio.isNotEmpty ? bio : 'No description available',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

