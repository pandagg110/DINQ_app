import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'spotify/spotify_widget.dart';

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
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
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
    return SpotifyWidget(
      card: params.card,
      size: params.size,
    );
  }
}

