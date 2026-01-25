import 'package:flutter/material.dart';
import 'substack_layouts.dart';

class SubstackWidget extends StatelessWidget {
  const SubstackWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final bio = (metadata['bio'] as String?) ?? '';
    final subscriberCount = (metadata['subscriber_count'] as num?)?.toInt() ?? 0;
    final latestPost = metadata['latest_post'] as Map<String, dynamic>?;

    switch (size) {
      case '2x2':
        return SubstackLayouts.build2x2Layout(
          subscriberCount: subscriberCount,
        );
      case '2x4':
        return SubstackLayouts.build2x4Layout(
          bio: bio,
          subscriberCount: subscriberCount,
        );
      case '4x2':
        return SubstackLayouts.build4x2Layout(
          bio: bio,
          subscriberCount: subscriberCount,
        );
      case '4x4':
        return SubstackLayouts.build4x4Layout(
          subscriberCount: subscriberCount,
          bio: bio,
          latestPost: latestPost,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

