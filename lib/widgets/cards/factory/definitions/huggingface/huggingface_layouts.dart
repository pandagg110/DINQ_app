import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import 'huggingface_components.dart';

class HuggingFaceLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required Map<String, dynamic> metrics,
  }) {
    final models = (metrics['models'] as num?)?.toInt() ?? 0;
    final datasets = (metrics['datasets'] as num?)?.toInt() ?? 0;
    final spaces = (metrics['spaces'] as num?)?.toInt() ?? 0;
    final papers = (metrics['papers'] as num?)?.toInt() ?? 0;
    final followers = (metrics['followers'] as num?)?.toInt() ?? 0;
    final following = (metrics['following'] as num?)?.toInt() ?? 0;

    final metricsArray = [
      {'type': 'models', 'value': models, 'bgColor': const Color(0xFFFDE277)},
      {'type': 'datasets', 'value': datasets, 'bgColor': const Color(0xFFE2C6FF)},
      {'type': 'spaces', 'value': spaces, 'bgColor': const Color(0xFFDDFEBC)},
      {'type': 'papers', 'value': papers, 'bgColor': const Color(0xFFCCE5FF)},
      {'type': 'followers', 'value': followers, 'bgColor': const Color(0xFFD9D9D9)},
      {'type': 'following', 'value': following, 'bgColor': const Color(0xFFFED7D7)},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/HuggingFace.png', size: 40),
          // Metrics Badges - 3 rows, 2 per row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row
              Row(
                children: metricsArray
                    .take(2)
                    .map((metric) => Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 4),
                          child: HuggingFaceComponents.buildMetricBadge(
                            type: metric['type'] as String,
                            value: metric['value'] as int,
                            bgColor: metric['bgColor'] as Color,
                            compact: true,
                          ),
                        ))
                    .toList(),
              ),
              // Second row
              Row(
                children: metricsArray
                    .skip(2)
                    .take(2)
                    .map((metric) => Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 4),
                          child: HuggingFaceComponents.buildMetricBadge(
                            type: metric['type'] as String,
                            value: metric['value'] as int,
                            bgColor: metric['bgColor'] as Color,
                            compact: true,
                          ),
                        ))
                    .toList(),
              ),
              // Third row
              Row(
                children: metricsArray
                    .skip(4)
                    .take(2)
                    .map((metric) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: HuggingFaceComponents.buildMetricBadge(
                            type: metric['type'] as String,
                            value: metric['value'] as int,
                            bgColor: metric['bgColor'] as Color,
                            compact: true,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    Map<String, dynamic>? featuredRepo,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/HuggingFace.png', size: 40),
          const SizedBox(height: 12),
          // Spacer to push content to bottom
          const Spacer(),
          // Repo Card
          HuggingFaceComponents.buildRepoCard(
            featuredRepo: featuredRepo,
            compact: true,
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    Map<String, dynamic>? featuredRepo,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/HuggingFace.png', size: 40),
          const SizedBox(height: 16),
          // Repo Card
          Expanded(
            child: HuggingFaceComponents.buildRepoCard(
              featuredRepo: featuredRepo,
            ),
          ),
        ],
      ),
    );
  }

  // 4x4 Size - Full
  static Widget build4x4Layout({
    required Map<String, dynamic> metrics,
    required String bioTitle,
    required String bioContent,
    required List<dynamic> organizations,
    required int organizationCount,
    Map<String, dynamic>? featuredRepo,
  }) {
    final models = (metrics['models'] as num?)?.toInt() ?? 0;
    final datasets = (metrics['datasets'] as num?)?.toInt() ?? 0;
    final spaces = (metrics['spaces'] as num?)?.toInt() ?? 0;
    final papers = (metrics['papers'] as num?)?.toInt() ?? 0;
    final followers = (metrics['followers'] as num?)?.toInt() ?? 0;
    final following = (metrics['following'] as num?)?.toInt() ?? 0;

    final metricsArray = [
      {'type': 'models', 'value': models, 'bgColor': const Color(0xFFFDE277)},
      {'type': 'datasets', 'value': datasets, 'bgColor': const Color(0xFFE2C6FF)},
      {'type': 'spaces', 'value': spaces, 'bgColor': const Color(0xFFDDFEBC)},
      {'type': 'papers', 'value': papers, 'bgColor': const Color(0xFFCCE5FF)},
      {'type': 'followers', 'value': followers, 'bgColor': const Color(0xFFD9D9D9)},
      {'type': 'following', 'value': following, 'bgColor': const Color(0xFFFED7D7)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/HuggingFace.png', size: 40),
          const SizedBox(height: 8),
          // Content Area
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable Metrics Badges
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: metricsArray
                      .map((metric) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: HuggingFaceComponents.buildMetricBadge(
                              type: metric['type'] as String,
                              value: metric['value'] as int,
                              bgColor: metric['bgColor'] as Color,
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Bio Section
              Center(
                child: Column(
                  children: [
                    Text(
                      bioTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bioContent,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Organizations Section
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Group
                    Row(
                      children: organizations.take(4).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final org = entry.value as Map<String, dynamic>;
                        final avatarUrl = org['avatarUrl'] as String? ?? '';
                        return Padding(
                          padding: EdgeInsets.only(left: index > 0 ? -8.0 : 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? Text('O${index + 1}', style: const TextStyle(fontSize: 10))
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Joined $organizationCount Organization${organizationCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Repo Card
              HuggingFaceComponents.buildRepoCard(
                featuredRepo: featuredRepo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

