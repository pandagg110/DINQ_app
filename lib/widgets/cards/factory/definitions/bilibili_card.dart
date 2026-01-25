import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'bilibili/bilibili_widget.dart';

class BilibiliCardDefinition extends CardDefinition {
  @override
  String get type => 'BILIBILI';

  @override
  String get icon => '/icons/social-icons/Bilibili.svg';

  @override
  String get name => 'Bilibili';

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
    final extra = data['extra'] ?? {};
    return {
      'mid': data['mid'] ?? 0,
      'name': data['name'] ?? '',
      'avatar': data['avatar'] ?? '',
      'followers': data['followers'] ?? 0,
      'following': data['following'] ?? 0,
      'likes': data['likes'] ?? 0,
      'archiveView': data['archive_view'] ?? 0,
      'articleView': data['article_view'] ?? 0,
      'bio': data['bio'] ?? '',
      'works': data['works'] ?? [],
      'level': extra['level'] ?? 0,
      'official': extra['official'],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return BilibiliWidget(
      card: params.card,
      size: params.size,
    );
  }
}

