import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class MediumCardDefinition extends CardDefinition {
  @override
  String get type => 'MEDIUM';

  @override
  String get icon => '/icons/social-icons/Medium.svg';

  @override
  String get name => 'Medium';

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
    final topArticle = data['top_article'];
    return {
      'username': data['username'],
      'name': data['name'],
      'bio': data['bio'],
      'avatar': data['avatar'],
      'followerCount': data['follower_count'],
      'followingCount': data['following_count'],
      'topArticle': topArticle != null
          ? {
              'title': topArticle['title'],
              'subtitle': topArticle['subtitle'],
              'url': topArticle['url'],
              'claps': topArticle['claps'],
              'responses': topArticle['responses'],
              'ogImage': topArticle['og_image'],
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final name = params.card.data.metadata['name']?.toString() ?? 'Medium';
    final username = params.card.data.metadata['username']?.toString() ?? '';
    final followers = params.card.data.metadata['followerCount'] ?? 0;
    final topArticle = params.card.data.metadata['topArticle'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Medium.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Followers: $followers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (topArticle?['title'] != null) ...[
            const SizedBox(height: 12),
            Text(
              topArticle!['title'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (topArticle['claps'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${topArticle['claps']} claps',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

