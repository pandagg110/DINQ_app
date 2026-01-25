import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class MediumLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int followerCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Medium.svg', size: 40),
          const Spacer(),
          // Stats
          MetricDisplay(
            label: 'Followers',
            value: followerCount,
            align: MetricAlign.start,
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required String bio,
    required int followerCount,
    required int followingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Medium.svg', size: 40),
          const SizedBox(height: 12),
          // Bio
          if (bio.isNotEmpty) ...[
            Expanded(
              child: Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
          ] else
            const Spacer(),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Followers',
                value: followerCount,
                align: MetricAlign.start,
              ),
              const SizedBox(height: 12),
              MetricDisplay(
                label: 'Following',
                value: followingCount,
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
    required String name,
    required String username,
    required int followerCount,
    required int followingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssetIcon(asset: 'icons/social-icons/Medium.svg', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Stats
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Followers',
                  value: followerCount,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricDisplay(
                  label: 'Following',
                  value: followingCount,
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
    required int followerCount,
    required int followingCount,
    required String bio,
    Map<String, dynamic>? topArticle,
  }) {
    final descriptionContent = topArticle?['subtitle'] ?? topArticle?['title'] ?? bio;
    final coverImage = topArticle?['ogImage'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Medium.svg', size: 40),
          const SizedBox(height: 12),
          // Metrics
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Followers',
                  value: followerCount,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricDisplay(
                  label: 'Following',
                  value: followingCount,
                  align: MetricAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cover Image
          if (coverImage != null && coverImage.isNotEmpty)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  coverImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (coverImage != null && coverImage.isNotEmpty) const SizedBox(height: 12),
          // Description
          if (descriptionContent != null && descriptionContent.toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                descriptionContent.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
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

