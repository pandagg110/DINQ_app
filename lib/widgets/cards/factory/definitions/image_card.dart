import 'package:flutter/material.dart';
import '../card_definition.dart';

class ImageCardDefinition extends CardDefinition {
  @override
  String get type => 'IMAGE';

  @override
  String get icon => '/icons/image.svg';

  @override
  String get name => 'Image';

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
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    // Image card metadata is usually already in correct format
    return null; // No adaptation needed
  }

  @override
  Widget render(CardRenderParams params) {
    final url = params.card.data.metadata['url']?.toString() ?? '';
    final isVideo = params.card.data.metadata['isVideo'] == true;
    final caption = params.card.data.metadata['caption']?.toString() ?? '';

    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🖼️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text(
                'No media',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: isVideo
              ? _buildVideoPlayer(url)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🖼️', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (caption.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                caption,
                style: const TextStyle(fontSize: 14, color: Color(0xFF171717)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPlayer(String url) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Video',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

