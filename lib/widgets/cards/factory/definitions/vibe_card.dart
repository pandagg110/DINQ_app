import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'vibe/vibe_widget.dart';

class VibeCardDefinition extends CardDefinition {
  @override
  String get type => 'VIBE';

  @override
  String get icon => '/icons/social-icons/Vibe.svg';

  @override
  String get name => 'Vibe';

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
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
    final data = rawMetadata is Map ? (cardAdapterMap(rawMetadata)) : {};
    return {
      'totalDays': data['total_days'] ?? data['totalDays'] ?? 0,
      'totalTokens': data['total_tokens'] ?? data['totalTokens'] ?? 0,
      'platform': data['platform'] ?? '',
      'daily': data['daily'] ?? [],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return VibeWidget(card: params.card, size: params.size);
  }
}
