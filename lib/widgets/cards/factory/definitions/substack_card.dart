import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

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
    final name = params.card.data.metadata['name']?.toString() ?? 'Substack';
    final handle = params.card.data.metadata['handle']?.toString() ?? '';
    final subscribers = params.card.data.metadata['subscriber_count'] ?? 0;
    final latestPost = params.card.data.metadata['latest_post'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Substack.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$handle',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Subscribers: $subscribers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (latestPost != null && latestPost['title'] != null) ...[
            const SizedBox(height: 12),
            Text(
              latestPost['title'],
              style: const TextStyle(fontSize: 12, color: Color(0xFF171717)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

