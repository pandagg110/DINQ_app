import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'instagram_hover_card.dart';

class InstagramComponents {
  // User Profile Component
  static Widget buildUserProfile({
    required String username,
    required String fullName,
    required String profileImage,
    required bool verified,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: InstagramHoverCard(
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

  // Latest Post Component
  static Widget buildLatestPost({
    required Map<String, dynamic> latestPost,
  }) {
    final text = latestPost['text'] as String? ?? '';
    final ogImage = latestPost['ogImage'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty)
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.33,
              color: Color(0xFF0F1419),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (ogImage != null && ogImage.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Spacer(),
          AspectRatio(
            aspectRatio: 1.9,
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
        ],
      ],
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

