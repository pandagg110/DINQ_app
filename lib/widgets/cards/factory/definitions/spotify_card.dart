import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class SpotifyCardDefinition extends CardDefinition {
  @override
  String get type => 'SPOTIFY';

  @override
  String get icon => '/icons/social-icons/Spotify.svg';

  @override
  String get name => 'Spotify';

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
      return 'Spotify URL is required';
    }

    try {
      final uri = Uri.parse(url);
      final validHostnames = ['open.spotify.com', 'spotify.com'];
      if (!validHostnames.contains(uri.host)) {
        return 'Invalid Spotify URL. Please use a valid Spotify track, album, playlist, artist, episode, or show URL';
      }

      final pathMatch = RegExp(r'^/(track|album|playlist|artist|episode|show)/([a-zA-Z0-9]+)')
          .firstMatch(uri.path);
      if (pathMatch == null) {
        return 'Invalid Spotify URL. Please use a valid Spotify track, album, playlist, artist, episode, or show URL';
      }
    } catch (e) {
      return 'Invalid URL format';
    }

    return null; // Validation passed
  }

  @override
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    final data = rawMetadata['data'] ?? rawMetadata;
    return {
      'url': data['url'] ?? '',
      'source': data['source'] ?? '',
      'author': data['author'] ?? '',
      'title': data['title'] ?? '',
      'thumbnail': data['thumbnail'] ?? '',
      'duration': data['duration'] ?? '',
      'medias': data['medias'] ?? [],
      'type': data['type'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final title = params.card.data.metadata['title']?.toString() ?? 'Spotify';
    final author = params.card.data.metadata['author']?.toString() ?? '';
    final thumbnail = params.card.data.metadata['thumbnail']?.toString();
    final size = params.size;

    if (size == '4x4' && thumbnail != null && thumbnail.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1DB954),
                child: const Center(child: Icon(Icons.music_note, size: 48, color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Spotify.svg', size: 32),
          const SizedBox(height: 12),
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              author,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }
}

