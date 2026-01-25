import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'scholar/scholar_widget.dart';

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
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
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
    return ScholarWidget(
      card: params.card,
      size: params.size,
    );
  }
}

