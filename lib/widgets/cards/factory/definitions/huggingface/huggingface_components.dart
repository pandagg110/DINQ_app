import 'package:flutter/material.dart';

class HuggingFaceComponents {
  // Format count utility
  static String formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  // Metric Badge Component
  static Widget buildMetricBadge({
    required String type,
    required int value,
    required Color bgColor,
    bool compact = false,
  }) {
    Widget? icon;
    switch (type) {
      case 'models':
        icon = Icon(Icons.model_training, size: compact ? 12 : 16);
        break;
      case 'datasets':
        icon = Icon(Icons.storage, size: compact ? 12 : 16);
        break;
      case 'spaces':
        icon = Icon(Icons.space_dashboard, size: compact ? 12 : 16);
        break;
      case 'papers':
        icon = Icon(Icons.description, size: compact ? 12 : 16);
        break;
      case 'followers':
        icon = Icon(Icons.people, size: compact ? 12 : 16);
        break;
      case 'following':
        icon = Icon(Icons.person_add, size: compact ? 12 : 16);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            formatCount(value),
            style: TextStyle(
              fontSize: compact ? 11 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // Repo Card Component
  static Widget buildRepoCard({
    Map<String, dynamic>? featuredRepo,
    bool compact = false,
  }) {
    if (featuredRepo == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCCE5FF)),
        ),
        child: const Center(
          child: Text(
            'No representative work on HuggingFace',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    final type = featuredRepo['type'] as String? ?? 'model';
    final name = featuredRepo['name'] as String? ?? '';
    final description = featuredRepo['description'] as String? ?? '';
    final downloads = (featuredRepo['downloads'] as num?)?.toInt() ?? 0;
    final likes = (featuredRepo['likes'] as num?)?.toInt() ?? 0;
    final updatedAt = featuredRepo['updatedAt'] as String? ?? '';

    String getTypeTitle() {
      switch (type) {
        case 'model':
          return 'Model';
        case 'dataset':
          return 'Dataset';
        case 'space':
          return 'Space';
        default:
          return 'Work';
      }
    }

    if (compact) {
      // Compact version for 2x4 layout
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCCE5FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFCCE5FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                getTypeTitle(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Divider(height: 16, thickness: 1),
                  Row(
                    children: [
                      if (downloads > 0) ...[
                        Icon(Icons.download, size: 10, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          formatCount(downloads),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (likes > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.favorite, size: 10, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          formatCount(likes),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (updatedAt.isNotEmpty) ...[
                    const Divider(height: 16, thickness: 1),
                    Text(
                      'Updated $updatedAt',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Full version for 4x2 and 4x4 layouts
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: const BoxDecoration(
              color: Color(0xFFCCE5FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTypeTitle(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Row(
                  children: [
                    if (downloads > 0) ...[
                      Icon(Icons.download, size: 12, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        formatCount(downloads),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                      ),
                    ],
                    if (likes > 0) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.favorite, size: 12, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        formatCount(likes),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Repo name with divider
                Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFCCE5FF), width: 1),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Updated time
                if (updatedAt.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Created $updatedAt',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
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

