import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../../../../common/metric_display.dart';

class OpenReviewLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required int totalPapers,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/OpenReview.png', size: 40),
          // Bottom Section: Papers Info
          Align(
            alignment: Alignment.bottomLeft,
            child: MetricDisplay(
              label: 'Papers',
              value: totalPapers,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required int totalPapers,
    required int collaboratorCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/OpenReview.png', size: 40),
          // Bottom Section: Metrics - Left aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetricDisplay(
                label: 'Papers',
                value: totalPapers,
                align: MetricAlign.start,
              ),
              const SizedBox(height: 16),
              MetricDisplay(
                label: 'Collaborators',
                value: collaboratorCount,
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
    required int totalPapers,
    required int collaboratorCount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/OpenReview.png', size: 40),
          // Bottom Section: Two Metric Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD8D8D8)),
                  ),
                  child: MetricDisplay(
                    label: 'Papers',
                    value: totalPapers,
                    align: MetricAlign.start,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD8D8D8)),
                  ),
                  child: MetricDisplay(
                    label: 'Collaborators',
                    value: collaboratorCount,
                    align: MetricAlign.start,
                  ),
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
    required int totalPapers,
    required int collaboratorCount,
    required Map<String, dynamic> representativeWork,
  }) {
    final title = (representativeWork['title'] as String?) ?? '';
    final authors = (representativeWork['authors'] as List<dynamic>?) ?? [];
    final publicationDate = (representativeWork['publicationDate'] as String?) ?? '';
    final venue = (representativeWork['venue'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/OpenReview.png', size: 40),
          const SizedBox(height: 16),
          // Metrics Section: Two Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD8D8D8)),
                  ),
                  child: MetricDisplay(
                    label: 'Papers',
                    value: totalPapers,
                    align: MetricAlign.start,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD8D8D8)),
                  ),
                  child: MetricDisplay(
                    label: 'Collaborators',
                    value: collaboratorCount,
                    align: MetricAlign.start,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Paper Details Section - with background
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Paper Title and Authors
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Paper Title
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.43,
                              color: Color(0xFF171717),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        // Authors
                        if (authors.isNotEmpty)
                          Text(
                            authors.map((a) => a.toString()).join(', '),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.43,
                              color: Color(0xFF171717),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Publication Info - 固定在底部
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (publicationDate.isNotEmpty)
                        Text(
                          'Published: $publicationDate',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.43,
                            color: Color.fromRGBO(48, 48, 48, 0.64),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (venue.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          venue,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.43,
                            color: Color.fromRGBO(48, 48, 48, 0.64),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

