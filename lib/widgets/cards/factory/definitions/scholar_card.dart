import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class ScholarCardDefinition extends CardDefinition {
  @override
  String get type => 'SCHOLAR';

  @override
  String get icon => '/icons/social-icons/GoogleScholar.svg';

  @override
  String get name => 'Google Scholar';

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
      'scholarId': data['scholar_id'] ?? '',
      'topTierPapers': data['top_tier_papers'] ?? 0,
      'totalPapers': data['total_papers'] ?? 0,
      'totalCitations': data['total_citations'] ?? 0,
      'firstAuthorCitations': data['first_author_citations'] ?? 0,
      'hIndex': data['h_index'] ?? 0,
      'summary': data['summary'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final name = params.card.data.metadata['name']?.toString() ?? 'Google Scholar';
    final totalCitations = params.card.data.metadata['totalCitations'] ?? 0;
    final totalPapers = params.card.data.metadata['totalPapers'] ?? 0;
    final hIndex = params.card.data.metadata['hIndex'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/GoogleScholar.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Citations: $totalCitations',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (totalPapers > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Papers: $totalPapers',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          if (hIndex > 0) ...[
            const SizedBox(height: 4),
            Text(
              'H-index: $hIndex',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

