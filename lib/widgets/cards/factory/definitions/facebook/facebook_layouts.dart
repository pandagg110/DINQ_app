import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class FacebookLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int followers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
          const Spacer(),
          // Stats
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
    required String title,
    required String pageName,
    required int followers,
    required int following,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
          const SizedBox(height: 12),
          // Title and Page Name
          if (title.isNotEmpty || pageName.isNotEmpty) ...[
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            if (pageName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@$pageName',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
            const Spacer(),
          ] else
            const Spacer(),
          // Stats
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
                label: 'Following',
                value: following,
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
    required String title,
    required String pageName,
    required int followers,
    required int following,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    if (pageName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@$pageName',
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
          const Spacer(),
          // Stats
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
                  label: 'Following',
                  value: following,
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
    required String title,
    required String pageName,
    required int followers,
    required int following,
    required String intro,
    Map<String, dynamic>? latestPost,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      if (pageName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$pageName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Stats - right aligned
              Row(
                children: [
                  MetricDisplay(
                    label: 'Followers',
                    value: followers,
                    align: MetricAlign.end,
                  ),
                  const SizedBox(width: 24),
                  MetricDisplay(
                    label: 'Following',
                    value: following,
                    align: MetricAlign.end,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Latest Post Image
          if (latestPost?['ogImage'] != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  latestPost!['ogImage'] as String,
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
          if (latestPost?['ogImage'] != null) const SizedBox(height: 12),
          // Intro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              latestPost?['text']?.toString() ?? intro,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF171717),
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

