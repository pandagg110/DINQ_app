import 'package:flutter/material.dart';
import 'bilibili_layouts.dart';

class BilibiliWidget extends StatelessWidget {
  const BilibiliWidget({
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
    final likes = (metadata['likes'] as num?)?.toInt() ?? 0;
    final archiveView = (metadata['archiveView'] as num?)?.toInt() ?? 0;
    final bio = (metadata['bio'] as String?) ?? '';
    final works = (metadata['works'] as List<dynamic>?) ?? [];
    final firstWork = works.isNotEmpty ? works[0] as Map<String, dynamic>? : null;

    switch (size) {
      case '2x2':
        return BilibiliLayouts.build2x2Layout(
          followers: followers,
        );
      case '2x4':
        return BilibiliLayouts.build2x4Layout(
          followers: followers,
          archiveView: archiveView,
          firstWork: firstWork,
        );
      case '4x2':
        return BilibiliLayouts.build4x2Layout(
          followers: followers,
          archiveView: archiveView,
          likes: likes,
        );
      case '4x4':
        return BilibiliLayouts.build4x4Layout(
          followers: followers,
          archiveView: archiveView,
          bio: bio,
          firstWork: firstWork,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

