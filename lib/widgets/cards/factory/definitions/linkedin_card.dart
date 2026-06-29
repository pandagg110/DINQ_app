import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'linkedin/linkedin_widget.dart';

class LinkedInCardDefinition extends CardDefinition {
  @override
  String get type => 'LINKEDIN';

  @override
  String get icon => '/icons/logo/LinkedIn.png';

  @override
  String get name => 'LinkedIn';

  @override
  CardAddFlow? get addFlow => CardAddFlow.url;

  @override
  String? get urlPlaceholder => 'linkedin.com/in/username';

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
    // Support the same shapes as the web adapter:
    // [...] or { linkedin: [...] }, plus already-adapted { careerJourney: [...] }.
    if (rawMetadata is Map && rawMetadata['careerJourney'] is List) {
      return Map<String, dynamic>.from(rawMetadata);
    }

    final rawData = cardAdapterData(rawMetadata);
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

    return {'careerJourney': careerJourney};
  }

  @override
  Widget render(CardRenderParams params) {
    return LinkedInWidget(card: params.card, size: params.size);
  }
}
