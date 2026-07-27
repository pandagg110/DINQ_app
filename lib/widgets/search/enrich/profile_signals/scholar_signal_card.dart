import 'package:flutter/material.dart';

import '../../../common/asset_icon.dart';
import 'profile_signals_analysis_button.dart';
import 'profile_signals_shared.dart';

class ScholarProfileSignalCard extends StatelessWidget {
  const ScholarProfileSignalCard({
    super.key,
    required this.metadata,
    this.url,
  });

  final Map<String, dynamic> metadata;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final topTierPapers = (metadata['topTierPapers'] as num?)?.toInt() ?? 0;
    final totalCitations = (metadata['totalCitations'] as num?)?.toInt() ?? 0;
    final firstAuthorCitations =
        (metadata['firstAuthorCitations'] as num?)?.toInt() ?? 0;
    final hIndex = (metadata['hIndex'] as num?)?.toInt() ?? 0;
    final summary = metadata['summary']?.toString() ?? '';
    final analysisUrl = url ?? metadata['url']?.toString();
    final scholarId = metadata['scholarId']?.toString() ??
        metadata['scholar_id']?.toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/logo/GoogleScholar.png', size: 40),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProfileSignalMetricTile(
                  label: 'Top Tier',
                  value: topTierPapers,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProfileSignalMetricTile(
                  label: 'Citations',
                  value: totalCitations,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ProfileSignalMetricTile(
                  label: 'First Author Citations',
                  value: firstAuthorCitations,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProfileSignalMetricTile(
                  label: 'H-index',
                  value: hIndex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              summary.isNotEmpty ? summary : 'No summary available.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.43,
                color: Color(0xFF171717),
              ),
            ),
          ),
          if (analysisUrl != null && analysisUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ProfileSignalAnalysisButton(
              platform: 'scholar',
              url: analysisUrl,
              fallbackId: scholarId,
            ),
          ],
        ],
      ),
    );
  }
}
