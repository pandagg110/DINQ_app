import 'package:flutter/material.dart';

class CareerTrajectoryModal extends StatelessWidget {
  const CareerTrajectoryModal({
    super.key,
    required this.segment,
    required this.representative,
    required this.colorScheme,
    required this.colorSchemeName,
    required this.onClose,
  });

  final Map<String, dynamic> segment;
  final Map<String, dynamic> representative;
  final Map<String, Color> colorScheme;
  final String colorSchemeName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: colorScheme['main'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme['divider']!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: (representative['avatarUrl'] as String?) != null
                        ? NetworkImage(representative['avatarUrl'] as String)
                        : null,
                    child: (representative['avatarUrl'] as String?) == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          representative['name'] as String? ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (representative['dinq'] ?? representative['position'] ?? '') as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme['textGray'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(color: colorScheme['divider'], height: 1),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme['textGray'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Brief
                    if (representative['brief'] != null && (representative['brief'] as String).isNotEmpty)
                      Text(
                        representative['brief'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme['textGray'],
                        ),
                      ),
                    
                    // Additional info can be added here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

