import 'package:flutter/material.dart';
import 'huggingface_layouts.dart';

class HuggingFaceWidget extends StatelessWidget {
  const HuggingFaceWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final metrics = (metadata['metrics'] as Map<String, dynamic>?) ?? {};
    final bioTitle = (metadata['bioTitle'] as String?) ?? 'AI ML Interests';
    final bioContent = (metadata['bioContent'] as String?) ?? '';
    final organizations = (metadata['organizations'] as List<dynamic>?) ?? [];
    final organizationCount = (metadata['organizationCount'] as num?)?.toInt() ?? 0;
    final featuredRepo = metadata['featuredRepo'] as Map<String, dynamic>?;
    debugPrint('bioContentbioContentbioContent: $bioContent');
    switch (size) {
      case '2x2':
        return HuggingFaceLayouts.build2x2Layout(
          metrics: metrics,
        );
      case '2x4':
        return HuggingFaceLayouts.build2x4Layout(
          featuredRepo: featuredRepo,
        );
      case '4x2':
        return HuggingFaceLayouts.build4x2Layout(
          featuredRepo: featuredRepo,
        );
      case '4x4':
        return HuggingFaceLayouts.build4x4Layout(
          metrics: metrics,
          bioTitle: bioTitle,
          bioContent: bioContent,
          organizations: organizations,
          organizationCount: organizationCount,
          featuredRepo: featuredRepo,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

