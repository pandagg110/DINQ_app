import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class RedditCardDefinition extends CardDefinition {
  @override
  String get type => 'REDDIT';

  @override
  String get icon => '/icons/social-icons/Reddit.svg';

  @override
  String get name => 'Reddit';

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
      'name': data['name'] ?? '',
      'total_karma': data['total_karma'] ?? 0,
      'icon_img': data['icon_img'] ?? '',
      'created': data['created'] ?? 0,
      'created_utc': data['created_utc'] ?? 0,
      'account_age_days': data['account_age_days'] ?? 0,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final name = params.card.data.metadata['name']?.toString() ?? 'Reddit';
    final karma = params.card.data.metadata['total_karma'] ?? 0;
    final accountAge = params.card.data.metadata['account_age_days'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Reddit.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Karma: $karma',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (accountAge > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Account age: ${accountAge} days',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

