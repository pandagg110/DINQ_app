import 'package:flutter/material.dart';

/// 与 TSX AdvisorsList 对应
class AdvisorsList extends StatelessWidget {
  const AdvisorsList({
    super.key,
    required this.advisors,
  });

  final List<Map<String, dynamic>> advisors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: advisors.map((a) {
          final name = a['name'] as String? ?? 'Advisor';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Text(name, style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
