import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/asset_path.dart';

/// Google Scholar card, aligned with Web ShareCard/cards/ScholarCard.tsx.
class ScholarCard extends StatelessWidget {
  const ScholarCard({
    super.key,
    this.topTierPapers,
    this.totalPapers,
    this.hIndex,
    this.summary,
  });

  final int? topTierPapers;
  final int? totalPapers;
  final int? hIndex;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final hasContent =
        topTierPapers != null && totalPapers != null && hIndex != null;
    final hasSummary = summary != null && summary!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            assetPath('icons/social-icons/Scholar.svg'),
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 18),
          if (hasContent)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MetricBlock(
                        label: 'Top Tier/Papers',
                        value: '$topTierPapers/$totalPapers',
                      ),
                      const SizedBox(width: 48),
                      _MetricBlock(label: 'H-index', value: '$hIndex'),
                    ],
                  ),
                  if (hasSummary) ...[
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          summary!,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 20,
                            color: Color(0xFF374151),
                            height: 1.6,
                          ),
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          assetPath('icons/error.svg'),
                          width: 48,
                          height: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No content yet.',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 24,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
