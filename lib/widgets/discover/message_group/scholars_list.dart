import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../stores/search_store.dart';

/// 与 TSX ScholarsList 对应
class ScholarsList extends StatelessWidget {
  const ScholarsList({
    super.key,
    required this.candidates,
    required this.groupId,
    required this.isLoading,
    this.onCandidateClick,
  });

  final List<Map<String, dynamic>> candidates;
  final int groupId;
  final bool isLoading;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)?
      onCandidateClick;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Text(
                '${candidates.length} Candidates',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidates.asMap().entries.map((e) {
                  final c = e.value;
                  final name = c['name'] as String? ?? 'Unknown';
                  final imageUrl = c['image_url'] as String?;
                  final idx = e.key;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (onCandidateClick != null) {
                          onCandidateClick!(c, idx, groupId);
                        } else {
                          final store = context.read<SearchStore>();
                          store.openTabWithClick(c, index: idx, groupId: groupId);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                              const CircleAvatar(
                                radius: 14,
                                child: Icon(Icons.person, size: 20),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
