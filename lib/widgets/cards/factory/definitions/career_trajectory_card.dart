import 'package:flutter/material.dart';
import '../card_definition.dart';

class CareerTrajectoryCardDefinition extends CardDefinition {
  @override
  String get type => 'CAREER_TRAJECTORY';

  @override
  String get icon => 'i-lucide-trending-up';

  @override
  String get name => 'Career Trajectory';

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
    // rawMetadata is an array of segments
    final segments = (rawMetadata is List ? rawMetadata : []) as List<dynamic>;
    
    final adaptedSegments = segments.asMap().entries.map((entry) {
      final index = entry.key;
      final segment = entry.value as Map<String, dynamic>;
      final roleModel = segment['role_model'] as Map<String, dynamic>?;
      
      Map<String, dynamic> representative;
      if (roleModel != null) {
        final data = roleModel['data'] as Map<String, dynamic>?;
        representative = {
          'name': roleModel['name'] ?? data?['name'] ?? 'Unknown',
          'position': data?['highlight'] ?? 
                      data?['company'] ?? 
                      data?['institution'] ?? 
                      'Unknown Position',
          'dinq': data?['dinq'],
          'avatarUrl': roleModel['photo'] ?? data?['photo'] ?? '/images/default-avatar.svg',
          'brief': roleModel['brief'] ?? data?['brief'] ?? '',
          'highlight': data?['highlight'] ?? '',
          'school': roleModel['school'] ?? data?['school'] ?? '',
          'companyLogo': null,
          'location': null,
          'socialMedia': roleModel['social_media'] != null
              ? {
                  'linkedin': roleModel['social_media']?['linkedin'],
                  'github': roleModel['social_media']?['github'],
                  'scholar': roleModel['social_media']?['scholar'],
                  'twitter': roleModel['social_media']?['twitter'],
                }
              : null,
        };
      } else {
        representative = {
          'name': 'Unknown',
          'position': 'Unknown Position',
          'dinq': null,
          'avatarUrl': '/images/default-avatar.svg',
          'brief': '',
          'highlight': '',
          'school': '',
          'companyLogo': null,
          'location': null,
          'socialMedia': null,
        };
      }

      // Get color based on category type
      final categoryType = segment['type']?.toString() ?? '';
      final color = _getCareerColor(categoryType, index);

      return {
        'category': categoryType,
        'percentage': segment['probability'] ?? 0,
        'color': color,
        'representative': representative,
      };
    }).toList();

    return {
      'segments': adaptedSegments,
    };
  }

  String _getCareerColor(String type, int index) {
    // Simplified color mapping - you may want to match the TypeScript version exactly
    final colors = [
      '#1487FA', // developer - blue
      '#DDFEBC', // researcher - green
      '#FFE4CC', // entrepreneur - orange
      '#E2C6FF', // educator - purple
    ];
    
    switch (type.toLowerCase()) {
      case 'developer':
        return '#1487FA';
      case 'researcher':
        return '#DDFEBC';
      case 'entrepreneur':
        return '#FFE4CC';
      case 'educator':
        return '#E2C6FF';
      default:
        return colors[index % colors.length];
    }
  }

  @override
  Widget render(CardRenderParams params) {
    final segments = params.card.data.metadata['segments'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Career Trajectory',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (segments.isNotEmpty)
            ...segments.take(3).map((segment) {
              final segMap = segment as Map<String, dynamic>;
              final category = segMap['category']?.toString() ?? '';
              final percentage = segMap['percentage'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(segMap['color']?.toString() ?? '#1487FA'),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$category (${(percentage * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            const Text(
              'No career trajectory data',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF1487FA);
    } catch (e) {
      return const Color(0xFF1487FA);
    }
  }
}

