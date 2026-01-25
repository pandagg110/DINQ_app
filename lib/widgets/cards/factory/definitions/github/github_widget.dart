import 'package:flutter/material.dart';
import 'github_layouts.dart';

class GitHubWidget extends StatelessWidget {
  const GitHubWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final username = (card.data.metadata['username'] as String?) ?? '';
    final starCount = (card.data.metadata['starCount'] as num?)?.toInt() ??
        (card.data.metadata['totalStars'] as num?)?.toInt() ??
        (card.data.metadata['total_stars'] as num?)?.toInt() ??
        0;
    final topLanguages = (card.data.metadata['topLanguages'] as List<dynamic>?) ??
        (card.data.metadata['top_languages'] as List<dynamic>?) ??
        [];
    final summary = (card.data.metadata['summary'] as String?) ?? '';
    final representativeProject = card.data.metadata['representativeProject'] ??
        card.data.metadata['representative_project'];
    final displayMode = (card.data.metadata['displayMode'] as String?) ?? 'project';
    final showActivity = displayMode == 'activity';

    switch (size) {
      case '2x2':
        return GitHubLayouts.build2x2Layout(
          username: username,
          starCount: starCount,
        );
      case '2x4':
        return GitHubLayouts.build2x4Layout(
          username: username,
          starCount: starCount,
          topLanguages: topLanguages.cast<String>(),
        );
      case '4x2':
        return GitHubLayouts.build4x2Layout(
          username: username,
          starCount: starCount,
          topLanguages: topLanguages.cast<String>(),
        );
      case '4x4':
        return GitHubLayouts.build4x4Layout(
          username: username,
          starCount: starCount,
          topLanguages: topLanguages.cast<String>(),
          summary: summary,
          representativeProject: representativeProject,
          showActivity: showActivity,
        );
      default:
        return GitHubLayouts.build4x4Layout(
          username: username,
          starCount: starCount,
          topLanguages: topLanguages.cast<String>(),
          summary: summary,
          representativeProject: representativeProject,
          showActivity: showActivity,
        );
    }
  }
}

