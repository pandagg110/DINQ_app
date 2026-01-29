import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class ScholarLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int totalCitations,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/GoogleScholar.png', size: 40),
          
          // Bottom Section: Citations
          Align(
            alignment: Alignment.bottomLeft,
            child: MetricDisplay(
              label: 'Citations',
              value: totalCitations,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required int totalCitations,
    required int topTierPapers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/GoogleScholar.png', size: 40),
          
          // Bottom Section: Metrics
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Citations',
                value: totalCitations,
                align: MetricAlign.start,
              ),
              const SizedBox(height: 16),
              MetricDisplay(
                label: 'Top Tier',
                value: topTierPapers,
                align: MetricAlign.start,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    required int totalCitations,
    required int topTierPapers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/GoogleScholar.png', size: 40),
          
          // Bottom Section: Metrics
          Row(
            children: [
              Expanded(
                child: MetricDisplay(
                  label: 'Citations',
                  value: totalCitations,
                  align: MetricAlign.start,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MetricDisplay(
                  label: 'Top Tier',
                  value: topTierPapers,
                  align: MetricAlign.start,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4x4 Size - Full
  static Widget build4x4Layout({
    required int topTierPapers,
    required int totalCitations,
    required int firstAuthorCitations,
    required int hIndex,
    required String summary,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/GoogleScholar.png', size: 40),
          
          const SizedBox(height: 16),
          
          // Metrics Grid: 2×2 Grid of Cards
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Top Left: Top Tier/Papers
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD8D8D8)),
                          ),
                          child: MetricDisplay(
                            label: 'Top Tier',
                            value: topTierPapers,
                            align: MetricAlign.start,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Top Right: Citations
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD8D8D8)),
                          ),
                          child: MetricDisplay(
                            label: 'Citations',
                            value: totalCitations,
                            align: MetricAlign.start,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      // Bottom Left: First Author Citations
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD8D8D8)),
                          ),
                          child: MetricDisplay(
                            label: 'First Author Citations',
                            value: firstAuthorCitations,
                            align: MetricAlign.start,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Bottom Right: H-index
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD8D8D8)),
                          ),
                          child: MetricDisplay(
                            label: 'H-index',
                            value: hIndex,
                            align: MetricAlign.start,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary Section
          Container(
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
        ],
      ),
    );
  }
}

