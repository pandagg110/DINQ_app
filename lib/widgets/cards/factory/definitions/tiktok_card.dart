import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'tiktok/tiktok_widget.dart';

class TikTokCardDefinition extends CardDefinition {
  @override
  String get type => 'TIKTOK';

  @override
  String get icon => '/icons/social-icons/Tiktok.svg';

  @override
  String get name => 'TikTok';

  @override
  CardAddFlow? get addFlow => CardAddFlow.url;

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
    final data = rawMetadata is Map ? (rawMetadata['data'] ?? rawMetadata) : {};
    final topVideo = data['top_video'] ?? data['topVideo'];

    return {
      'username': data['username'] ?? '',
      'name': data['name'] ?? '',
      'avatar': data['avatar'] ?? '',
      'followerCount': data['follower_count'] ?? data['followerCount'] ?? 0,
      'followingCount': data['following_count'] ?? data['followingCount'] ?? 0,
      'likeCount': data['like_count'] ?? data['likeCount'] ?? 0,
      'url': data['url'] ?? '',
      'topVideo': topVideo is Map
          ? {
              'title': topVideo['title'] ?? '',
              'url': topVideo['url'] ?? '',
              'likes': topVideo['likes'] ?? 0,
              'comments': topVideo['comments'] ?? 0,
              'shares': topVideo['shares'] ?? 0,
              'views': topVideo['views'] ?? 0,
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return TikTokWidget(
      card: params.card,
      size: params.size,
      editable: params.editable,
    );
  }
}
