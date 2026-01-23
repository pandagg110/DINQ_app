import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class LinkCardDefinition extends CardDefinition {
  @override
  String get type => 'LINK';

  @override
  String get icon => '/icons/link-image.svg';

  @override
  String get name => 'Link';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '2x2',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '2x2',
        ),
      );

  @override
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    final data = rawMetadata['data'] ?? rawMetadata;
    return {
      'url': data['url'] ?? '',
      'title': data['title'],
      'favicon': data['favicon'],
      'og_image': data['og_image'],
      'screenshot_url': data['screenshot_url'],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final title = params.card.data.metadata['title']?.toString() ?? 'Link';
    final url = params.card.data.metadata['url']?.toString() ?? '';
    final ogImage = params.card.data.metadata['og_image']?.toString();
    final size = params.size;

    if (size == '4x4' && ogImage != null && ogImage.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              ogImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Center(child: Icon(Icons.link, size: 48, color: Colors.grey)),
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
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      url,
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
          const AssetIcon(asset: 'icons/link-image.svg', size: 32),
          const SizedBox(height: 12),
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              url,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

