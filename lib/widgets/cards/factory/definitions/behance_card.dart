import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'behance/behance_widget.dart';

class BehanceCardDefinition extends CardDefinition {
  @override
  String get type => 'BEHANCE';

  @override
  String get icon => '/icons/social-icons/Behance.svg';

  @override
  String get name => 'Behance';

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
    final data = rawMetadata['data'] ?? rawMetadata;
    return {
      'username': data['username'] ?? '',
      'name': data['name'] ?? data['display_name'] ?? '',
      'display_name': data['display_name'] ?? '',
      'bio': data['bio'] ?? '',
      'avatar': data['avatar'] ?? '',
      'followers': data['followers'] ?? data['followers_count'] ?? 0,
      'followers_count': data['followers_count'] ?? 0,
      'following_count': data['following_count'] ?? 0,
      'views': data['views'] ?? data['project_views'] ?? 0,
      'project_views': data['project_views'] ?? 0,
      'likes': data['likes'] ?? data['appreciations'] ?? 0,
      'appreciations': data['appreciations'] ?? 0,
      'newest_work': data['newest_work'],
      'latest_projects': data['latest_projects'] ?? [],
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return BehanceWidget(
      card: params.card,
      size: params.size,
    );
  }
}

