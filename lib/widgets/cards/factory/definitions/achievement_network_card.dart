import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'achievement_network/network_widget.dart';

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
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
    // Handle both Map and direct data structure
    final data = rawMetadata is Map<String, dynamic> 
        ? (rawMetadata['data'] ?? rawMetadata)
        : rawMetadata;
    final items = data is List ? data : [];
    
    // Also check for connections array directly
    final connectionsData = rawMetadata is Map<String, dynamic>
        ? (rawMetadata['connections'] as List<dynamic>?)
        : null;
    
    final connectionsList = connectionsData ?? items;
    
    final topConnections = (connectionsList as List).take(6).map((person) {
      final personMap = person as Map<String, dynamic>;
      return {
        'name': personMap['name'] ?? '',
        'avatarUrl': personMap['avatarUrl'] ?? personMap['avatar_url'] ?? '/images/default-avatar.svg',
        'institution_logo_url': personMap['institution_logo_url'],
        'affiliation': personMap['affiliation'] ?? '',
        'position': personMap['position'] ?? '',
        'relationshipType': personMap['relationshipType'] ?? personMap['relationship_type'] ?? '',
        'score': personMap['score'] ?? personMap['final_score'] ?? 0,
        'reason': personMap['reason'] ?? personMap['reason_for_inclusion'] ?? '',
      };
    }).toList();

    return {
      'connections': topConnections,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return NetworkWidget(
      card: params.card,
      size: params.size,
    );
  }
}

