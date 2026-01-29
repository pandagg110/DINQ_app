import 'package:flutter/material.dart';

class CareerHoverCard extends StatelessWidget {
  const CareerHoverCard({
    super.key,
    required this.representative,
    required this.segment,
    required this.colorScheme,
    required this.colorSchemeName,
  });

  final Map<String, dynamic> representative;
  final Map<String, dynamic> segment;
  final Map<String, Color> colorScheme;
  final String colorSchemeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme['main'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme['divider']!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: (representative['avatarUrl'] as String?) != null
                    ? NetworkImage(representative['avatarUrl'] as String)
                    : null,
                child: (representative['avatarUrl'] as String?) == null
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      representative['name'] as String? ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (representative['dinq'] ?? representative['position'] ?? '') as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme['textGray'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme['divider'], height: 1),
          const SizedBox(height: 12),
          
          // Category
          Text(
            (segment['category'] as String? ?? '')
                .isEmpty
                ? ''
                : (segment['category'] as String)
                    .substring(0, 1)
                    .toUpperCase() +
                    (segment['category'] as String).substring(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme['textGray'],
            ),
          ),
          const SizedBox(height: 8),
          
          // Brief
          if (representative['brief'] != null && (representative['brief'] as String).isNotEmpty)
            Text(
              representative['brief'] as String,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme['textGray'],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

