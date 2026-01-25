import 'package:flutter/material.dart';
import 'facebook_layouts.dart';

class FacebookWidget extends StatelessWidget {
  const FacebookWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final followers = (metadata['followers'] as num?)?.toInt() ?? 0;
    final following = (metadata['following'] as num?)?.toInt() ?? 0;
    final intro = (metadata['intro'] as String?) ?? '';
    final pageName = (metadata['pageName'] as String?) ?? '';
    final title = (metadata['title'] as String?) ?? '';
    final latestPost = metadata['latestPost'] as Map<String, dynamic>?;

    switch (size) {
      case '2x2':
        return FacebookLayouts.build2x2Layout(
          followers: followers,
        );
      case '2x4':
        return FacebookLayouts.build2x4Layout(
          title: title,
          pageName: pageName,
          followers: followers,
          following: following,
        );
      case '4x2':
        return FacebookLayouts.build4x2Layout(
          title: title,
          pageName: pageName,
          followers: followers,
          following: following,
        );
      case '4x4':
        return FacebookLayouts.build4x4Layout(
          title: title,
          pageName: pageName,
          followers: followers,
          following: following,
          intro: intro,
          latestPost: latestPost,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

