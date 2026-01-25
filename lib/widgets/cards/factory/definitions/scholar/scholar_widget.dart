import 'package:flutter/material.dart';
import 'scholar_layouts.dart';

class ScholarWidget extends StatelessWidget {
  const ScholarWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final topTierPapers = (card.data.metadata['topTierPapers'] as num?)?.toInt() ?? 0;
    final totalCitations = (card.data.metadata['totalCitations'] as num?)?.toInt() ?? 0;
    final firstAuthorCitations = (card.data.metadata['firstAuthorCitations'] as num?)?.toInt() ?? 0;
    final hIndex = (card.data.metadata['hIndex'] as num?)?.toInt() ?? 0;
    final summary = (card.data.metadata['summary'] as String?) ?? '';

    switch (size) {
      case '2x2':
        return ScholarLayouts.build2x2Layout(
          totalCitations: totalCitations,
        );
      case '2x4':
        return ScholarLayouts.build2x4Layout(
          totalCitations: totalCitations,
          topTierPapers: topTierPapers,
        );
      case '4x2':
        return ScholarLayouts.build4x2Layout(
          totalCitations: totalCitations,
          topTierPapers: topTierPapers,
        );
      case '4x4':
        return ScholarLayouts.build4x4Layout(
          topTierPapers: topTierPapers,
          totalCitations: totalCitations,
          firstAuthorCitations: firstAuthorCitations,
          hIndex: hIndex,
          summary: summary,
        );
      default:
        return ScholarLayouts.build4x4Layout(
          topTierPapers: topTierPapers,
          totalCitations: totalCitations,
          firstAuthorCitations: firstAuthorCitations,
          hIndex: hIndex,
          summary: summary,
        );
    }
  }
}

