import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class NeteaseCardDefinition extends CardDefinition {
  @override
  String get type => 'NETEASE';

  @override
  String get icon => '/icons/social-icons/Netease.svg';

  @override
  String get name => 'Netease';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
      );

  @override
  String? validate(Map<String, dynamic> metadata) {
    final url = metadata['url']?.toString();
    if (url == null || url.isEmpty) {
      return 'Netease music URL is required';
    }

    try {
      final uri = Uri.parse(url);
      final hostname = uri.host.toLowerCase();
      if (!hostname.endsWith('music.163.com')) {
        return 'Please use a valid music.163.com song, album, or playlist URL';
      }

      final pathToCheck = '${uri.path}${uri.fragment}';
      final validPaths = RegExp(r'(\/|#\/)(song|playlist|album)');
      if (!validPaths.hasMatch(pathToCheck)) {
        return 'Please use a song, album, or playlist URL from music.163.com';
      }
    } catch (e) {
      return 'Invalid URL format';
    }

    return null; // Validation passed
  }

  @override
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    final data = rawMetadata['data'] ?? rawMetadata;
    final playlist = data['playlist'] as List<dynamic>? ?? [];
    final firstTrack = playlist.isNotEmpty ? playlist[0] : null;
    final rawTitle = data['title']?.toString() ?? '';

    String artist = firstTrack?['artist']?.toString() ?? '';
    String songTitle = firstTrack?['title']?.toString() ?? '';

    if ((artist.isEmpty || songTitle.isEmpty) && rawTitle.contains(' - ')) {
      final parts = rawTitle.split(' - ');
      if (parts.length >= 2) {
        artist = artist.isEmpty ? parts[0].trim() : artist;
        songTitle = songTitle.isEmpty ? parts.sublist(1).join(' - ').trim() : songTitle;
      }
    }

    return {
      'link': data['link'] ?? '',
      'title': rawTitle,
      'songTitle': songTitle.isNotEmpty ? songTitle : rawTitle,
      'artist': artist,
      'coverImageUrl': data['coverImageUrl'] ?? '',
      'playlist': playlist,
      'description': data['description'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final title = params.card.data.metadata['title']?.toString() ?? 'Netease';
    final artist = params.card.data.metadata['artist']?.toString() ?? '';
    final coverImageUrl = params.card.data.metadata['coverImageUrl']?.toString();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Netease.svg', size: 32),
          const SizedBox(height: 12),
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          if (artist.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              artist,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
          if (coverImageUrl != null && coverImageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverImageUrl,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

