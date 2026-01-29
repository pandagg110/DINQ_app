import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'github/github_widget.dart';

class GitHubCardDefinition extends CardDefinition {
  @override
  String get type => 'GITHUB';

  @override
  String get icon => '/icons/logo/Github.png';

  @override
  String get name => 'GitHub';

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
    // Handle both nested (.data) and flat structures
    final data = rawMetadata['data'] ?? rawMetadata;
    return {
      'username': data['username'] ?? '',
      'starCount': data['total_stars'] ?? data['totalStars'] ?? data['starCount'] ?? 0,
      'topLanguages': data['top_languages'] ?? data['topLanguages'] ?? [],
      'summary': data['summary'] ?? '',
      'representativeProject': data['representative_project'] ?? data['representativeProject'],
      'displayMode': rawMetadata['displayMode'] ?? data['displayMode'],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return GitHubWidget(
      card: params.card,
      size: params.size,
    );
  }
}

