import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'netease_layouts.dart';

class NeteaseWidget extends StatefulWidget {
  const NeteaseWidget({
    super.key,
    required this.card,
    required this.size,
    required this.editable,
  });

  final dynamic card;
  final String size;
  final bool editable;

  @override
  State<NeteaseWidget> createState() => _NeteaseWidgetState();
}

class _NeteaseWidgetState extends State<NeteaseWidget> {
  static const _audioChannel = MethodChannel('dinq/netease_audio');

  String _previewUrl = '';
  bool _isPlaying = false;

  Future<void> _togglePlay() async {
    if (_previewUrl.isEmpty) return;

    if (_isPlaying) {
      await _audioChannel.invokeMethod<void>('pause');
      if (mounted) {
        setState(() => _isPlaying = false);
      }
      return;
    }

    try {
      await _audioChannel.invokeMethod<void>('play', {
        'url': _previewUrl,
        'headers': _audioHeaders,
      });
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    } catch (error, stackTrace) {
      debugPrint('Netease preview playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  static const Map<String, String> _audioHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
    'Referer': 'https://music.163.com/',
  };

  @override
  Widget build(BuildContext context) {
    final metadata = widget.card.data.metadata;
    final artist = (metadata['artist'] as String?) ?? '';
    final songTitle =
        (metadata['songTitle'] as String?) ??
        (metadata['title'] as String?) ??
        '';
    final coverImageUrl = (metadata['coverImageUrl'] as String?) ?? '';
    final link =
        (metadata['link'] as String?) ?? (metadata['url'] as String?) ?? '';
    final playlist = metadata['playlist'] as List<dynamic>? ?? [];
    final firstTrack = playlist.isNotEmpty ? playlist.first : null;
    _previewUrl = _resolvePreviewUrl(
      metadata: metadata,
      firstTrack: firstTrack,
      link: link,
    );

    switch (widget.size) {
      case '2x2':
        return NeteaseLayouts.build2x2Layout(
          songTitle: songTitle,
          artist: artist,
          link: link,
          isPlaying: _isPlaying,
          hasPreview: _previewUrl.isNotEmpty,
          onPlayTap: _togglePlay,
        );
      case '2x4':
        return NeteaseLayouts.build2x4Layout(
          songTitle: songTitle,
          artist: artist,
          coverImageUrl: coverImageUrl,
          link: link,
          isPlaying: _isPlaying,
          hasPreview: _previewUrl.isNotEmpty,
          onPlayTap: _togglePlay,
        );
      case '4x2':
        return NeteaseLayouts.build4x2Layout(
          songTitle: songTitle,
          artist: artist,
          coverImageUrl: coverImageUrl,
          link: link,
          isPlaying: _isPlaying,
          hasPreview: _previewUrl.isNotEmpty,
          onPlayTap: _togglePlay,
        );
      case '4x4':
        return NeteaseLayouts.build4x4Layout(
          songTitle: songTitle,
          artist: artist,
          coverImageUrl: coverImageUrl,
          link: link,
          isPlaying: _isPlaying,
          hasPreview: _previewUrl.isNotEmpty,
          onPlayTap: _togglePlay,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }

  String _resolvePreviewUrl({
    required Map<dynamic, dynamic> metadata,
    required dynamic firstTrack,
    required String link,
  }) {
    const urlKeys = [
      'url',
      'previewUrl',
      'preview_url',
      'mp3Url',
      'mp3_url',
      'audioUrl',
      'audio_url',
      'songUrl',
      'song_url',
    ];

    if (firstTrack is Map) {
      for (final key in urlKeys) {
        final value = firstTrack[key]?.toString().trim() ?? '';
        if (_isHttpUrl(value)) return value;
      }

      final id = firstTrack['id']?.toString().trim() ?? '';
      final derived = _outerSongUrl(id);
      if (derived.isNotEmpty) return derived;
    }

    for (final key in urlKeys) {
      final value = metadata[key]?.toString().trim() ?? '';
      if (_isHttpUrl(value) && !value.contains('music.163.com')) return value;
    }

    return _outerSongUrl(_extractSongId(link));
  }

  bool _isHttpUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  String _outerSongUrl(String id) {
    if (id.isEmpty) return '';
    return 'http://music.163.com/song/media/outer/url?id=$id.mp3';
  }

  String _extractSongId(String link) {
    if (link.isEmpty) return '';

    final uri = Uri.tryParse(link);
    if (uri == null) return '';

    final queryId = uri.queryParameters['id'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final fragmentUri = Uri.tryParse(uri.fragment);
    final fragmentId = fragmentUri?.queryParameters['id'];
    if (fragmentId != null && fragmentId.isNotEmpty) return fragmentId;

    final match = RegExp(r'(?:song\?id=|/song/)(\d+)').firstMatch(link);
    return match?.group(1) ?? '';
  }
}
