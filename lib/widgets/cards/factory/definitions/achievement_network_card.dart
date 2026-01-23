import 'package:flutter/material.dart';
import '../card_definition.dart';

class AchievementNetworkCardDefinition extends CardDefinition {
  @override
  String get type => 'ACHIEVEMENT_NETWORK';

  @override
  String get icon => 'i-lucide-network';

  @override
  String get name => 'Network';

  @override
  CardViewModeSizes get sizes => const CardViewModeSizes(
        desktop: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
        mobile: CardSizeConfig(
          supported: ['2x2', '2x4', '4x2', '4x4'],
          defaultSize: '4x4',
        ),
      );

  @override
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    final data = rawMetadata['data'] ?? rawMetadata;
    final items = data is List ? data : [];
    
    final topConnections = items.take(6).map((person) {
      final personMap = person as Map<String, dynamic>;
      return {
        'name': personMap['name'] ?? '',
        'avatarUrl': personMap['avatar_url'] ?? '/images/default-avatar.svg',
        'institution_logo_url': personMap['institution_logo_url'],
        'affiliation': personMap['affiliation'] ?? '',
        'position': personMap['position'] ?? '',
        'relationshipType': personMap['relationship_type'] ?? '',
        'score': personMap['final_score'] ?? 0,
        'reason': personMap['reason_for_inclusion'] ?? '',
      };
    }).toList();

    return {
      'connections': topConnections,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final connections = params.card.data.metadata['connections'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (connections.isNotEmpty)
            ...connections.take(4).map((connection) {
              final connMap = connection as Map<String, dynamic>;
              final name = connMap['name']?.toString() ?? '';
              final position = connMap['position']?.toString() ?? '';
              final avatarUrl = connMap['avatarUrl']?.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (avatarUrl != null && avatarUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(avatarUrl),
                        onBackgroundImageError: (_, __) {},
                      )
                    else
                      const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          if (position.isNotEmpty)
                            Text(
                              position,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            const Text(
              'No network data',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

