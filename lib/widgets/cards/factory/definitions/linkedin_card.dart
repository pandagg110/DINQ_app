import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class LinkedInCardDefinition extends CardDefinition {
  @override
  String get type => 'LINKEDIN';

  @override
  String get icon => '/icons/social-icons/LinkedIn.svg';

  @override
  String get name => 'LinkedIn';

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
    // Support both: { data: { linkedin: [...] } } and { data: [...] }
    final rawData = rawMetadata['data'] ?? rawMetadata;
    List<dynamic> items;
    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map && rawData['linkedin'] is List) {
      items = rawData['linkedin'] as List;
    } else {
      items = [];
    }

    // Extract start year from duration string
    int extractStartYear(String duration) {
      final match = RegExp(r'^(\d{4})').firstMatch(duration);
      return match != null ? int.parse(match.group(1)!) : DateTime.now().year;
    }

    // Backend returns newest first, reverse to show oldest first (timeline order)
    final careerJourney = items.reversed.map((item) {
      final itemMap = item as Map<String, dynamic>;
      return {
        'logo': itemMap['logo'] ?? '',
        'name': itemMap['name'] ?? '',
        'position': itemMap['position'] ?? '',
        'score': itemMap['score'] ?? 0,
        'year': extractStartYear(itemMap['duration']?.toString() ?? ''),
        'duration': itemMap['duration'] ?? '',
      };
    }).toList();

    return {
      'careerJourney': careerJourney,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final careerJourney = params.card.data.metadata['careerJourney'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/LinkedIn.svg', size: 32),
          const SizedBox(height: 12),
          if (careerJourney.isNotEmpty) ...[
            Text(
              'Career Journey',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...careerJourney.take(3).map((item) {
              final itemMap = item as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${itemMap['year']}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${itemMap['position']} @ ${itemMap['name']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else
            const Text(
              'LinkedIn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

