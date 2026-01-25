import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/metric_display.dart';

class GitHubComponents {
  static Widget buildRepresentativeProjectCard(dynamic project) {
    final name = (project['name'] as String?) ?? '';
    final url = (project['url'] as String?);
    final stars = (project['stars'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCE5FF)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFCCE5FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 16, color: Color(0xFF374151)),
                const SizedBox(width: 6),
                Expanded(
                  child: url != null && url.isNotEmpty
                      ? GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(url);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Text(
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
              ],
            ),
          ),
          // Stars
          Padding(
            padding: const EdgeInsets.all(12),
            child: MetricDisplay(
              label: 'Stars',
              value: stars,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

