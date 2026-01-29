import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'facebook/facebook_widget.dart';

class FacebookCardDefinition extends CardDefinition {
  @override
  String get type => 'FACEBOOK';

  @override
  String get icon => '/icons/social-icons/Facebook.svg';

  @override
  String get name => 'Facebook';

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
    final latestPost = data['latest_post'];
    return {
      'title': data['title'] ?? '',
      'pageName': data['pageName'] ?? '',
      'followers': data['followers'] ?? 0,
      'following': data['followings'] ?? 0,
      'intro': data['intro'] ?? '',
      'profilePicture': data['profilePictureUrl'] ?? '',
      'latestPost': latestPost != null
          ? {
              'url': latestPost['url'] ?? '',
              'mediaUrl': latestPost['media_url'] ?? '',
              'ogImage': latestPost['og_image'] ?? '',
              'text': latestPost['text'] ?? '',
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return FacebookWidget(
      card: params.card,
      size: params.size,
    );
  }
}

