import 'package:flutter/material.dart';

/// 与 TSX DinqResultsView 对应
class DinqResultsView extends StatelessWidget {
  const DinqResultsView({
    super.key,
    required this.results,
    required this.loading,
  });

  final List<Map<String, dynamic>> results;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (_) => Container(
              width: 160,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No DINQ users found. Try different keywords.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Found ${results.length} DINQ Fellows. Visit their DINQ Card for more.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: results.map((r) {
              final name = r['name'] as String? ?? 'Unknown';
              final imageUrl = r['image_url'] as String?;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 28),
                        ),
                      )
                    else
                      const Icon(Icons.person, size: 28),
                    const SizedBox(width: 8),
                    Text(name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
