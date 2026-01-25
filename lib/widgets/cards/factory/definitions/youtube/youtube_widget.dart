import 'package:flutter/material.dart';
import 'youtube_layouts.dart';

class YouTubeWidget extends StatelessWidget {
  const YouTubeWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final subscriberCount = (metadata['subscriberCount'] as num?)?.toInt() ?? 0;
    final viewCount = (metadata['viewCount'] as num?)?.toInt() ?? 0;
    final videoEmbedCode = (metadata['videoEmbedCode'] as String?) ?? '';
    final summary = (metadata['summary'] as String?) ?? '';

    switch (size) {
      case '2x2':
        return YouTubeLayouts.build2x2Layout(
          subscriberCount: subscriberCount,
        );
      case '2x4':
        return YouTubeLayouts.build2x4Layout(
          videoEmbedCode: videoEmbedCode,
          subscriberCount: subscriberCount,
          viewCount: viewCount,
        );
      case '4x2':
        return YouTubeLayouts.build4x2Layout(
          subscriberCount: subscriberCount,
          viewCount: viewCount,
        );
      case '4x4':
        return YouTubeLayouts.build4x4Layout(
          videoEmbedCode: videoEmbedCode,
          subscriberCount: subscriberCount,
          viewCount: viewCount,
          summary: summary,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

