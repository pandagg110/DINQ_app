import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'openreview/openreview_widget.dart';

class OpenReviewCardDefinition extends CardDefinition {
  @override
  String get type => 'OPENREVIEW';

  @override
  String get icon => '/icons/logo/OpenReview.png';

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
    final data = cardAdapterMap(rawMetadata);
    final work =
        data['representative_work'] ?? data['representativeWork'] ?? {};
    return {
      'totalPapers': data['totalPapers'] ?? data['total_papers'] ?? 0,
      'collaboratorCount':
          data['collaboratorCount'] ?? data['collaborator_count'] ?? 0,
      'representativeWork': {
        'title': work['title'] ?? '',
        'venue': work['venue'] ?? '',
        'authors': work['authors'] ?? [],
        'publicationDate':
            work['publicationDate'] ?? work['publication_date'] ?? '',
      },
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return OpenReviewWidget(card: params.card, size: params.size);
  }
}
