import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/asset_path.dart';

/// Google Scholar 卡片，对应 Web ShareCard/cards/ScholarCard.tsx（简化版）
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
    final hasContent = topTierPapers != null && totalPapers != null && hIndex != null;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetPath('icons/social-icons/Scholar.svg'),
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 18),
          if (hasContent) ...[
            Row(
              children: [
                _MetricBlock(
                  label: 'Top Tier/Papers',
                  value: '$topTierPapers/$totalPapers',
                ),
                const SizedBox(width: 48),
                _MetricBlock(label: 'h-index', value: '$hIndex'),
              ],
            ),
            if (summary != null && summary!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                summary!,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 20,
                  color: Color(0xFF171717),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'No content yet.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 24,
                    color: Color(0xFF000000),
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
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }
}
