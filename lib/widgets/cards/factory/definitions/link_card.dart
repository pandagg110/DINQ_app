import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'link/link_widget.dart';

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
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
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
    return LinkWidget(
      card: params.card,
      size: params.size,
    );
  }
}

