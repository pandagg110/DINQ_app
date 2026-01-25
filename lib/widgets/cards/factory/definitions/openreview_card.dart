import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class OpenReviewCardDefinition extends CardDefinition {
  @override
  String get type => 'OPENREVIEW';

  @override
  String get icon => '/icons/social-icons/OpenReview.svg';

  @override
  String get name => 'OpenReview';

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
    final work = data['representative_work'] ?? {};
    return {
      'totalPapers': data['total_papers'] ?? 0,
      'collaboratorCount': data['collaborator_count'] ?? 0,
      'representativeWork': {
        'title': work['title'] ?? '',
        'venue': work['venue'] ?? '',
        'authors': work['authors'] ?? [],
        'publicationDate': work['publication_date'] ?? '',
      },
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final totalPapers = params.card.data.metadata['totalPapers'] ?? 0;
    final collaboratorCount = params.card.data.metadata['collaboratorCount'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/OpenReview.svg', size: 32),
          const SizedBox(height: 12),
          const Text(
            'OpenReview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Papers: $totalPapers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          Text(
            'Collaborators: $collaboratorCount',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

