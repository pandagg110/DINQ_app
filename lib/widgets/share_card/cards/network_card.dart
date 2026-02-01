import 'package:flutter/material.dart';

/// Network 卡片，对应 Web ShareCard/cards/NetworkCard.tsx（简化版）
class NetworkCard extends StatelessWidget {
  const NetworkCard({
    super.key,
    this.connections = const [],
    this.currentUserAvatar,
  });

  final List<dynamic> connections;
  final String? currentUserAvatar;

  @override
  Widget build(BuildContext context) {
    final displayList = connections.take(6).toList();
    final hasContent = displayList.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF323232).withOpacity(0.07), width: 2),
                ),
                child: const Icon(Icons.account_tree, size: 28, color: Color(0xFF323232)),
              ),
              const SizedBox(width: 16),
              const Text(
                'Network',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasContent)
            const Expanded(
              child: Center(
                child: Text(
                  'No content yet.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 24,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: displayList.asMap().entries.map((e) {
                final item = e.value;
                final avatarUrl = item is Map ? (item['avatar_url'] ?? item['avatarUrl'] ?? '') : '';
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFF3F4F6),
                    backgroundImage: avatarUrl.toString().isNotEmpty && avatarUrl.toString().startsWith('http')
                        ? NetworkImage(avatarUrl.toString())
                        : null,
                    child: avatarUrl.toString().isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
