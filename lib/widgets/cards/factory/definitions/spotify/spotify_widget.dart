import 'package:flutter/material.dart';
import 'spotify_layouts.dart';

class SpotifyWidget extends StatelessWidget {
  const SpotifyWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final author = (metadata['author'] as String?) ?? '';
    final title = (metadata['title'] as String?) ?? '';
    final thumbnail = (metadata['thumbnail'] as String?) ?? '';
    final url = (metadata['url'] as String?) ?? '';

    switch (size) {
      case '2x2':
        return SpotifyLayouts.build2x2Layout(
          author: author,
          title: title,
          url: url,
        );
      case '2x4':
        return SpotifyLayouts.build2x4Layout(
          author: author,
          title: title,
          thumbnail: thumbnail,
          url: url,
        );
      case '4x2':
        return SpotifyLayouts.build4x2Layout(
          author: author,
          title: title,
          thumbnail: thumbnail,
          url: url,
        );
      case '4x4':
        return SpotifyLayouts.build4x4Layout(
          author: author,
          title: title,
          thumbnail: thumbnail,
          url: url,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

