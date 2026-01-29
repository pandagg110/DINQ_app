import 'package:flutter/material.dart';

class NetworkHoverCard extends StatelessWidget {
  const NetworkHoverCard({
    super.key,
    required this.connection,
    required this.colorScheme,
  });

  final Map<String, dynamic> connection;
  final Map<String, Color> colorScheme;

  @override
  Widget build(BuildContext context) {
    final name = connection['name']?.toString() ?? '';
    final position = connection['position']?.toString() ?? '';
    final affiliation = connection['affiliation']?.toString() ?? '';
    final relationshipType = connection['relationshipType']?.toString() ?? '';
    final avatarUrl = connection['avatarUrl']?.toString();
    final reason = connection['reason']?.toString();

    return Container(
      width: 380,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: colorScheme['light'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF171717), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme['main'],
              border: Border(
                bottom: BorderSide(color: const Color(0xFF171717), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: Text(
                    relationshipType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF171717),
                    ),
                  ),
                ),
                Text(
                  'CONNECTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF171717).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default-avatar.svg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, size: 24);
                                },
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/default-avatar.svg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 24);
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF171717),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        position.isNotEmpty
                            ? '$position, $affiliation'
                            : affiliation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reason
          if (reason != null && reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF171717),
                    height: 1.7,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

