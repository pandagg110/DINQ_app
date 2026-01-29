import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class ThreadsCardDefinition extends CardDefinition {
  @override
  String get type => 'THREADS';

  @override
  String get icon => '/icons/social-icons/Threads.svg';

  @override
  String get name => 'Threads';

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
    final latestPost = data['latest_post'];
    return {
      'name': data['name'] ?? '',
      'handle': data['handle'] ?? '',
      'avatar': data['avatar'] ?? '',
      'followerCount': data['follower_count'] ?? 0,
      'latestPost': latestPost != null
          ? {
              'url': latestPost['url'] ?? '',
              'content': latestPost['content'] ?? '',
              'coverImage': latestPost['cover_image'] ?? '',
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final name = params.card.data.metadata['name']?.toString() ?? '';
    final handle = params.card.data.metadata['handle']?.toString() ?? '';
    final followers = params.card.data.metadata['followerCount'] ?? 0;
    final latestPost = params.card.data.metadata['latestPost'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Threads.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            name.isNotEmpty ? name : (handle.isNotEmpty ? '@$handle' : 'Threads'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Followers: $followers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (latestPost?['coverImage'] != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                latestPost!['coverImage'],
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

