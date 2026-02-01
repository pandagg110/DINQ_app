import 'package:flutter/material.dart';

/// Tags 卡片，对应 Web ShareCard/cards/TagsCard.tsx
class TagsCard extends StatelessWidget {
  const TagsCard({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF888888).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(minHeight: 54),
            alignment: Alignment.center,
            child: Text(
              tag,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF171717),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
