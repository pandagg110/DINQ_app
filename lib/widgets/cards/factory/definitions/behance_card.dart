import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class BehanceCardDefinition extends CardDefinition {
  @override
  String get type => 'BEHANCE';

  @override
  String get icon => '/icons/social-icons/Behance.svg';

  @override
  String get name => 'Behance';

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
    return {
      'username': data['username'] ?? '',
      'display_name': data['display_name'] ?? '',
      'bio': data['bio'] ?? '',
      'avatar': data['avatar'] ?? '',
      'followers_count': data['followers_count'] ?? 0,
      'following_count': data['following_count'] ?? 0,
      'project_views': data['project_views'] ?? 0,
      'appreciations': data['appreciations'] ?? 0,
      'latest_projects': data['latest_projects'] ?? [],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final displayName = params.card.data.metadata['display_name']?.toString() ??
        params.card.data.metadata['username']?.toString() ??
        'Behance';
    final followers = params.card.data.metadata['followers_count'] ?? 0;
    final appreciations = params.card.data.metadata['appreciations'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Behance.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Followers: $followers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (appreciations > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Appreciations: $appreciations',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

