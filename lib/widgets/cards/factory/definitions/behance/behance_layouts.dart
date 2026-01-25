import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class BehanceLayouts {
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
          const AssetIcon(asset: 'icons/social-icons/Behance.svg', size: 40),
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
    required int views,
    required int likes,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Behance.svg', size: 40),
          const SizedBox(height: 16),
          // Spacer
          const Spacer(),
          // Bottom Section: Three metrics vertical
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
                value: views,
                align: MetricAlign.start,
              ),
              const SizedBox(height: 16),
              MetricDisplay(
                label: 'Likes',
                value: likes,
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
    required int views,
    required int likes,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Behance.svg', size: 40),
          // Bottom Section: Three metrics - space between
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MetricDisplay(
                label: 'Followers',
                value: followers,
                align: MetricAlign.start,
              ),
              MetricDisplay(
                label: 'Views',
                value: views,
                align: MetricAlign.end,
              ),
              MetricDisplay(
                label: 'Likes',
                value: likes,
                align: MetricAlign.end,
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
    required int views,
    required int likes,
    Map<String, dynamic>? firstProject,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/social-icons/Behance.svg', size: 40),
          const SizedBox(height: 12),
          // Three metrics - space between
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Followers',
                value: followers,
                align: MetricAlign.start,
              ),
              MetricDisplay(
                label: 'Views',
                value: views,
                align: MetricAlign.end,
              ),
              MetricDisplay(
                label: 'Likes',
                value: likes,
                align: MetricAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Project cover image - takes most space
          if (firstProject?['cover'] != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  firstProject!['cover'] as String,
                  fit: BoxFit.cover,
                  width: double.infinity,
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
        ],
      ),
    );
  }
}

