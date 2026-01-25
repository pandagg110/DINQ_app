import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class BlueskyCardDefinition extends CardDefinition {
  @override
  String get type => 'BLUESKY';

  @override
  String get icon => '/icons/social-icons/BlueSky.svg';

  @override
  String get name => 'Bluesky';

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
      'handle': data['handle'] ?? '',
      'display_name': data['display_name'] ?? '',
      'description': data['description'] ?? '',
      'avatar': data['avatar'] ?? '',
      'og_image': data['og_image'] ?? '',
      'followers_count': data['followers_count'] ?? 0,
      'follows_count': data['follows_count'] ?? 0,
      'posts_count': data['posts_count'] ?? 0,
      'created_at': data['created_at'] ?? '',
      'url': data['url'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final handle = params.card.data.metadata['handle']?.toString() ?? '';
    final displayName = params.card.data.metadata['display_name']?.toString() ?? '';
    final followers = params.card.data.metadata['followers_count'] ?? 0;
    final posts = params.card.data.metadata['posts_count'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/BlueSky.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            displayName.isNotEmpty
                ? displayName
                : (handle.isNotEmpty ? '@$handle' : 'Bluesky'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Followers: $followers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (posts > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Posts: $posts',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

