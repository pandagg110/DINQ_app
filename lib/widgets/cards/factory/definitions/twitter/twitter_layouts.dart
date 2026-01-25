import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';
import 'twitter_components.dart';

class TwitterLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int followerCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Twitter.png', size: 40),
          // Bottom Section: Follower Count
          Align(
            alignment: Alignment.bottomLeft,
            child: MetricDisplay(
              label: 'Followers',
              value: followerCount,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required int followerCount,
    required int smartFollowerCount,
    required List<dynamic> topSmartFollowers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Twitter.png', size: 40),
          // Spacer
          const Spacer(),
          // Metrics Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Followers',
                value: followerCount,
                align: MetricAlign.start,
              ),
              if (topSmartFollowers.isNotEmpty) ...[
                const SizedBox(height: 16),
                TwitterComponents.buildTopSmartFollowers(
                  topSmartFollowers: topSmartFollowers,
                  smartFollowerCount: smartFollowerCount,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    required int followerCount,
    required int smartFollowerCount,
    required List<dynamic> topSmartFollowers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Twitter.png', size: 40),
          // Metrics Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Followers',
                value: followerCount,
                align: MetricAlign.start,
              ),
              if (topSmartFollowers.isNotEmpty) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TwitterComponents.buildTopSmartFollowers(
                      topSmartFollowers: topSmartFollowers,
                      smartFollowerCount: smartFollowerCount,
                      horizontal: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 4x4 Size - Full
  static Widget build4x4Layout({
    required String username,
    required String fullName,
    required String profileImage,
    required bool verified,
    required int followerCount,
    required int smartFollowerCount,
    required List<dynamic> topSmartFollowers,
    required String summary,
    Map<String, dynamic>? latestTweet,
    String? profileUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Followers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssetIcon(asset: 'icons/logo/Twitter.png', size: 40),
              MetricDisplay(
                label: 'Followers',
                value: followerCount,
                align: MetricAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 8), // mb-2
          // Middle Row: User Profile + Top Smart Followers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Profile Section
              Expanded(
                child: TwitterComponents.buildUserProfile(
                  username: username,
                  fullName: fullName,
                  profileImage: profileImage,
                  verified: verified,
                  profileUrl: profileUrl,
                ),
              ),
              // Top Smart Followers
              if (topSmartFollowers.isNotEmpty) ...[
                const SizedBox(width: 12),
                TwitterComponents.buildTopSmartFollowers(
                  topSmartFollowers: topSmartFollowers,
                  smartFollowerCount: smartFollowerCount,
                  compact: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4), // mb-1
          // Latest Tweet or Summary
          if (latestTweet != null) ...[
            Expanded(
              child: TwitterComponents.buildLatestTweet(
                latestTweet: latestTweet,
                pushImageToBottom: true,
              ),
            ),
          ] else if (summary.isNotEmpty) ...[
            Text(
              summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.33,
                color: Color(0xFF536471),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

