import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class GitHubCardDefinition extends CardDefinition {
  @override
  String get type => 'GITHUB';

  @override
  String get icon => '/icons/social-icons/Github.svg';

  @override
  String get name => 'GitHub';

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
    // Handle both nested (.data) and flat structures
    final data = rawMetadata['data'] ?? rawMetadata;
    return {
      'username': data['username'] ?? '',
      'starCount': data['total_stars'] ?? data['totalStars'] ?? data['starCount'] ?? 0,
      'topLanguages': data['top_languages'] ?? data['topLanguages'] ?? [],
      'summary': data['summary'] ?? '',
      'representativeProject': data['representative_project'] ?? data['representativeProject'],
      'displayMode': rawMetadata['displayMode'] ?? data['displayMode'],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final username = params.card.data.metadata['username']?.toString() ?? '';
    final stars = params.card.data.metadata['starCount'] ??
        params.card.data.metadata['totalStars'] ??
        0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Github.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            username.isNotEmpty ? '@$username' : 'GitHub',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Stars: $stars',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

