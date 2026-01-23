import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

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
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
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
    final name = params.card.data.metadata['name']?.toString() ?? 'Bilibili';
    final followers = params.card.data.metadata['followers'] ?? 0;
    final likes = params.card.data.metadata['likes'] ?? 0;
    final level = params.card.data.metadata['level'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Bilibili.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Followers: $followers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (likes > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Likes: $likes',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          if (level > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Level: $level',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

