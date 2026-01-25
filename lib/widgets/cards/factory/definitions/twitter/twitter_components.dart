import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'twitter_hover_card.dart';

class TwitterComponents {
  // User Profile Component
  static Widget buildUserProfile({
    required String username,
    required String fullName,
    required String profileImage,
    required bool verified,
    String? profileUrl,
  }) {
    final url = profileUrl ?? 'https://x.com/$username';
    
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image - 48x48 (size-12)
          ClipOval(
            child: Image.network(
              profileImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return SvgPicture.asset(
                  'assets/images/default-avatar.svg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F1419),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/icons/verified.svg',
                        width: 18,
                        height: 18,
                      ),
                    ],
                  ],
                ),
                Text(
                  '@$username',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF536471),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Smart Followers Component
  static Widget buildTopSmartFollowers({
    required List<dynamic> topSmartFollowers,
    required int smartFollowerCount,
    bool horizontal = false,
    bool compact = false,
  }) {
    final followers = topSmartFollowers.take(4).toList();
    
    return Column(
      crossAxisAlignment: horizontal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Top Smart Followers${smartFollowerCount > 0 ? ' (${_formatCount(smartFollowerCount)})' : ''}',
          style: TextStyle(
            fontSize: compact ? 10 : 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: compact ? 2.0 : 8.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: followers.asMap().entries.map((entry) {
            final index = entry.key;
            final follower = entry.value as Map<String, dynamic>;
            final avatarSrc = follower['profile_image'] ?? follower['avatarUrl'] ?? '';
            
            return Padding(
              padding: EdgeInsets.only(left: index > 0 ? -8.0 : 0.0),
              child: TwitterHoverCard(
                follower: follower,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarSrc,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return SvgPicture.asset(
                          'assets/images/default-avatar.svg',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Latest Tweet Component
  static Widget buildLatestTweet({
    required Map<String, dynamic> latestTweet,
  }) {
    final text = latestTweet['text'] as String? ?? '';
    final url = latestTweet['url'] as String? ?? '';
    final ogImage = latestTweet['ogImage'] as String?;

    // If there's an OG image, use Column with Spacer to push image to bottom
    if (ogImage != null && ogImage.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (text.isNotEmpty)
            InkWell(
              onTap: () async {
                if (url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.33,
                  color: Color(0xFF0F1419),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (text.isNotEmpty) const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              if (url.isNotEmpty) {
                final uri = Uri.parse(url);
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
                  ogImage,
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
      );
    }
    
    // If only text, return simple text widget
    if (text.isNotEmpty) {
      return InkWell(
        onTap: () async {
          if (url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.33,
            color: Color(0xFF0F1419),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    
    return const SizedBox.shrink();
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

