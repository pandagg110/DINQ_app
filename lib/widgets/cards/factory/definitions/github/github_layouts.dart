import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';
import 'github_constants.dart';
import 'github_components.dart';

class GitHubLayouts {
  // 2x2 Size - Bottom Left Card (Compact)
  static Widget build2x2Layout({
    required String username,
    required int starCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          Row(
            children: [
              const AssetIcon(asset: 'icons/logo/Github.png', size: 40),
            ],
          ),
          // Bottom Section: Stars
          Align(
            alignment: Alignment.bottomLeft,
            child: MetricDisplay(
              label: 'Stars',
              value: starCount,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required String username,
    required int starCount,
    required List<String> topLanguages,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/Github.png', size: 40),
          
          // Middle Section: Contribution Chart
          if (username.isNotEmpty)
            SizedBox(
              width: 140,
              height: 101,
              child: Image.network(
                'https://ghchart.rshah.org/$username',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: Text('Chart unavailable')),
                  );
                },
              ),
            ),
          
          // Bottom Section: Metrics
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Stars',
                value: starCount,
                align: MetricAlign.start,
              ),
              if (topLanguages.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Language Tags - Vertical Stack
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topLanguages.take(3).map((lang) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: GitHubConstants.getLanguageColor(lang),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$lang',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF171717),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Top Right Card (Horizontal: Left content + Right chart)
  static Widget build4x2Layout({
    required String username,
    required int starCount,
    required List<String> topLanguages,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: Icon + Stars + Languages
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Icon
                const AssetIcon(asset: 'icons/logo/Github.png', size: 40),
                
                // Bottom: Stars/Username + Language Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MetricDisplay(
                      label: 'Stars',
                      value: starCount,
                      align: MetricAlign.start,
                    ),
                    const SizedBox(width: 32),
                    // Language Tags - Vertical Stack
                    if (topLanguages.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: topLanguages.take(3).map((lang) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: GitHubConstants.getLanguageColor(lang),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '#$lang',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171717),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Right: Contribution Chart - bottom aligned
          if (username.isNotEmpty)
            SizedBox(
              width: 140,
              height: 101,
              child: Image.network(
                'https://ghchart.rshah.org/$username',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: Text('Chart unavailable')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // 4x4 Size - Full Card with optional representative work
  static Widget build4x4Layout({
    required String username,
    required int starCount,
    required List<String> topLanguages,
    required String summary,
    dynamic representativeProject,
    required bool showActivity,
  }) {
    final hasRepresentative = representativeProject != null &&
        (representativeProject['name'] as String?)?.isNotEmpty == true;
    final summaryText = summary.trim().isNotEmpty ? summary : 'No summary available.';
    final summaryClampLines = hasRepresentative ? 2 : 4;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon + Stars (right-aligned)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssetIcon(asset: 'icons/logo/Github.png', size: 40),
              MetricDisplay(
                label: 'Stars',
                value: starCount,
                align: MetricAlign.end,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Language Tags
                if (topLanguages.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topLanguages.map((lang) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: GitHubConstants.getLanguageColor(lang),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$lang',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF171717),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Show representative project OR contribution chart
                if (hasRepresentative && !showActivity)
                  GitHubComponents.buildRepresentativeProjectCard(representativeProject)
                else if (username.isNotEmpty)
                  SizedBox(
                    height: 101,
                    child: Image.network(
                      'https://ghchart.rshah.org/$username',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: Text('Chart unavailable')),
                        );
                      },
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
                    summaryText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: summaryClampLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

