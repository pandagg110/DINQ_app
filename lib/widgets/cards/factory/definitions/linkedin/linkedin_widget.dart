import 'package:flutter/material.dart';
import 'linkedin_layouts.dart';

class LinkedInWidget extends StatelessWidget {
  const LinkedInWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final careerJourney = (card.data.metadata['careerJourney'] as List<dynamic>?) ?? [];

    switch (size) {
      case '2x2':
        return LinkedInLayouts.build2x2Layout(
          careerJourney: careerJourney.cast<Map<String, dynamic>>(),
        );
      case '2x4':
        return LinkedInLayouts.build2x4Layout(
          careerJourney: careerJourney.cast<Map<String, dynamic>>(),
        );
      case '4x2':
        return LinkedInLayouts.build4x2Layout(
          careerJourney: careerJourney.cast<Map<String, dynamic>>(),
        );
      case '4x4':
        return LinkedInLayouts.build4x4Layout(
          careerJourney: careerJourney.cast<Map<String, dynamic>>(),
        );
      default:
        return LinkedInLayouts.build4x4Layout(
          careerJourney: careerJourney.cast<Map<String, dynamic>>(),
        );
    }
  }
}

