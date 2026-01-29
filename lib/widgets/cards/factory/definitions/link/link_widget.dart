import 'package:flutter/material.dart';
import 'link_layouts.dart';

class LinkWidget extends StatelessWidget {
  const LinkWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final url = (metadata['url'] as String?) ?? '';
    final title = (metadata['title'] as String?) ?? '';
    final favicon = (metadata['favicon'] as String?) ?? '';
    final rawOgImage = (metadata['og_image'] as String?) ?? '';
    final screenshotUrl = (metadata['screenshot_url'] as String?) ?? '';

    // Compute effective preview image: og_image -> screenshot_url
    final ogImage = rawOgImage.isNotEmpty ? rawOgImage : screenshotUrl;

    switch (size) {
      case '2x2':
        return LinkLayouts.build2x2Layout(
          title: title,
          url: url,
          favicon: favicon,
        );
      case '2x4':
        return LinkLayouts.build2x4Layout(
          title: title,
          url: url,
          favicon: favicon,
          ogImage: ogImage,
        );
      case '4x2':
        return LinkLayouts.build4x2Layout(
          title: title,
          url: url,
          favicon: favicon,
          ogImage: ogImage,
        );
      case '4x4':
        return LinkLayouts.build4x4Layout(
          title: title,
          url: url,
          favicon: favicon,
          ogImage: ogImage,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

