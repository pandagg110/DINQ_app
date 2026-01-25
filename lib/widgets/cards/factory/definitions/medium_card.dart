import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'medium/medium_widget.dart';

class MediumCardDefinition extends CardDefinition {
  @override
  String get type => 'MEDIUM';

  @override
  String get icon => '/icons/social-icons/Medium.svg';

  @override
  String get name => 'Medium';

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
    final topArticle = data['top_article'];
    return {
      'username': data['username'],
      'name': data['name'],
      'bio': data['bio'],
      'avatar': data['avatar'],
      'followerCount': data['follower_count'],
      'followingCount': data['following_count'],
      'topArticle': topArticle != null
          ? {
              'title': topArticle['title'],
              'subtitle': topArticle['subtitle'],
              'url': topArticle['url'],
              'claps': topArticle['claps'],
              'responses': topArticle['responses'],
              'ogImage': topArticle['og_image'],
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return MediumWidget(
      card: params.card,
      size: params.size,
    );
  }
}

