import 'package:flutter/material.dart';
import 'openreview_layouts.dart';

class OpenReviewWidget extends StatelessWidget {
  const OpenReviewWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final totalPapers = (metadata['totalPapers'] as num?)?.toInt() ?? 0;
    final collaboratorCount = (metadata['collaboratorCount'] as num?)?.toInt() ?? 0;
    final representativeWork = (metadata['representativeWork'] as Map<String, dynamic>?) ?? {};

    switch (size) {
      case '2x2':
        return OpenReviewLayouts.build2x2Layout(
          totalPapers: totalPapers,
        );
      case '2x4':
        return OpenReviewLayouts.build2x4Layout(
          totalPapers: totalPapers,
          collaboratorCount: collaboratorCount,
        );
      case '4x2':
        return OpenReviewLayouts.build4x2Layout(
          totalPapers: totalPapers,
          collaboratorCount: collaboratorCount,
        );
      case '4x4':
        return OpenReviewLayouts.build4x4Layout(
          totalPapers: totalPapers,
          collaboratorCount: collaboratorCount,
          representativeWork: representativeWork,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

