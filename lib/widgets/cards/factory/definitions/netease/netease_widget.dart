import 'package:flutter/material.dart';
import 'netease_layouts.dart';

class NeteaseWidget extends StatelessWidget {
  const NeteaseWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final artist = (metadata['artist'] as String?) ?? '';
    final songTitle = (metadata['songTitle'] as String?) ?? 
                     (metadata['title'] as String?) ?? '';
    final coverImageUrl = (metadata['coverImageUrl'] as String?) ?? '';
    final link = (metadata['link'] as String?) ?? 
                 (metadata['url'] as String?) ?? '';

    switch (size) {
      case '2x2':
        return NeteaseLayouts.build2x2Layout(
          songTitle: songTitle,
          artist: artist,
          link: link,
        );
      case '2x4':
        return NeteaseLayouts.build2x4Layout(
          songTitle: songTitle,
          artist: artist,
          coverImageUrl: coverImageUrl,
          link: link,
        );
      case '4x2':
        return NeteaseLayouts.build4x2Layout(
          songTitle: songTitle,
          artist: artist,
          coverImageUrl: coverImageUrl,
          link: link,
        );
      case '4x4':
        return NeteaseLayouts.build4x4Layout(
          songTitle: songTitle,
          artist: artist,
          coverImageUrl: coverImageUrl,
          link: link,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

