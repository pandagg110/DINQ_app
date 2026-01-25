import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class SubstackLayouts {
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
          const AssetIcon(asset: 'icons/social-icons/Substack.svg', size: 40),
          // Bottom Section: Subscribers
          MetricDisplay(
            label: 'Subscribers',
            value: subscriberCount,
            align: MetricAlign.start,
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required String bio,
    required int subscriberCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Substack.svg', size: 40),
          const SizedBox(height: 16),
          // Middle: Bio text
          if (bio.isNotEmpty)
            Expanded(
              child: Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (bio.isNotEmpty) const SizedBox(height: 16),
          // Bottom: Subscribers
          MetricDisplay(
            label: 'Subscribers',
            value: subscriberCount,
            align: MetricAlign.start,
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    required String bio,
    required int subscriberCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Substack.svg', size: 40),
          // Bottom: Subscribers + Bio
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: Subscribers
              MetricDisplay(
                label: 'Subscribers',
                value: subscriberCount,
                align: MetricAlign.start,
              ),
              const SizedBox(width: 24),
              // Right: Bio text
              if (bio.isNotEmpty)
                Expanded(
                  child: Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
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
    required int subscriberCount,
    required String bio,
    Map<String, dynamic>? latestPost,
  }) {
    final title = latestPost?['title'] as String?;
    final coverImage = latestPost?['cover_image'] as String?;
    final canonicalUrl = latestPost?['canonical_url'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Substack Icon
          const AssetIcon(asset: 'icons/social-icons/Substack.svg', size: 40),
          const SizedBox(height: 12),
          // Subscribers Metric
          MetricDisplay(
            label: 'Subscribers',
            value: subscriberCount,
            align: MetricAlign.start,
          ),
          const SizedBox(height: 12),
          // Latest Post - Title and Cover Image
          if (latestPost != null && title != null) ...[
            InkWell(
              onTap: () async {
                if (canonicalUrl != null && canonicalUrl.isNotEmpty) {
                  final uri = Uri.parse(canonicalUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.33,
                  color: Color(0xFF0F1419),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            if (coverImage != null && coverImage.isNotEmpty) ...[
              const Spacer(),
              InkWell(
                onTap: () async {
                  if (canonicalUrl != null && canonicalUrl.isNotEmpty) {
                    final uri = Uri.parse(canonicalUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: AspectRatio(
                  aspectRatio: 1.9, // 52.5% padding-bottom = ~1.9
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ] else if (bio.isNotEmpty) ...[
            Expanded(
              child: Text(
                bio,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.33,
                  color: Color(0xFF536471),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

