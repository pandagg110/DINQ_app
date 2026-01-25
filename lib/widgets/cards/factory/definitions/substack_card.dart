import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'substack/substack_widget.dart';

class SubstackCardDefinition extends CardDefinition {
  @override
  String get type => 'SUBSTACK';

  @override
  String get icon => '/icons/social-icons/Substack.svg';

  @override
  String get name => 'Substack';

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
    final data = rawMetadata['data'] ?? rawMetadata;
    return {
      'user_id': data['user_id'] ?? 0,
      'name': data['name'] ?? '',
      'handle': data['handle'] ?? '',
      'avatar': data['avatar'] ?? '',
      'bio': data['bio'] ?? '',
      'subscriber_count': data['subscriber_count'] ?? 0,
      'latest_post': data['latest_post'],
      'url': data['url'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return SubstackWidget(
      card: params.card,
      size: params.size,
    );
  }
}

