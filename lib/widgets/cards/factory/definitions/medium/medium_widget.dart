import 'package:flutter/material.dart';
import 'medium_layouts.dart';

class MediumWidget extends StatelessWidget {
  const MediumWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final followerCount = (metadata['followerCount'] as num?)?.toInt() ?? 0;
    final followingCount = (metadata['followingCount'] as num?)?.toInt() ?? 0;
    final name = (metadata['name'] as String?) ?? '';
    final username = (metadata['username'] as String?) ?? '';
    final bio = (metadata['bio'] as String?) ?? '';
    final topArticle = metadata['topArticle'] as Map<String, dynamic>?;

    switch (size) {
      case '2x2':
        return MediumLayouts.build2x2Layout(
          followerCount: followerCount,
        );
      case '2x4':
        return MediumLayouts.build2x4Layout(
          bio: bio,
          followerCount: followerCount,
          followingCount: followingCount,
        );
      case '4x2':
        return MediumLayouts.build4x2Layout(
          name: name,
          username: username,
          followerCount: followerCount,
          followingCount: followingCount,
        );
      case '4x4':
        return MediumLayouts.build4x4Layout(
          followerCount: followerCount,
          followingCount: followingCount,
          bio: bio,
          topArticle: topArticle,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

