import 'package:flutter/material.dart';
import 'instagram_layouts.dart';

class InstagramWidget extends StatelessWidget {
  const InstagramWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final username = (metadata['username'] as String?) ?? '';
    final fullName = (metadata['full_name'] as String?) ?? 'Instagram user';
    final profileImage = (metadata['profile_image'] as String?) ?? '/images/default-avatar.svg';
    final verified = (metadata['verified'] as bool?) ?? false;
    final followerCount = (metadata['followerCount'] as num?)?.toInt() ?? 0;
    final smartFollowerCount = (metadata['smartFollowerCount'] as num?)?.toInt() ?? 0;
    final topSmartFollowers = (metadata['topSmartFollowers'] as List<dynamic>?) ?? [];
    final summary = (metadata['summary'] as String?) ?? '';
    final profileUrl =
        (metadata['url'] as String?) ?? 'https://www.instagram.com/$username';
    final latestPost = metadata['latestPost'] as Map<String, dynamic>?;

    switch (size) {
      case '2x2':
        return InstagramLayouts.build2x2Layout(
          followerCount: followerCount,
        );
      case '2x4':
        return InstagramLayouts.build2x4Layout(
          followerCount: followerCount,
          smartFollowerCount: smartFollowerCount,
          topSmartFollowers: topSmartFollowers,
        );
      case '4x2':
        return InstagramLayouts.build4x2Layout(
          followerCount: followerCount,
          smartFollowerCount: smartFollowerCount,
          topSmartFollowers: topSmartFollowers,
        );
      case '4x4':
        return InstagramLayouts.build4x4Layout(
          username: username,
          fullName: fullName,
          profileImage: profileImage,
          verified: verified,
          followerCount: followerCount,
          smartFollowerCount: smartFollowerCount,
          topSmartFollowers: topSmartFollowers,
          summary: summary,
          latestPost: latestPost,
          profileUrl: profileUrl,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

