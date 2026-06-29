import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'twitter/twitter_widget.dart';

class TwitterCardDefinition extends CardDefinition {
  @override
  String get type => 'TWITTER';

  @override
  String get icon => '/icons/logo/Twitter.png';

  @override
  String get name => 'Twitter';

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
    final data = cardAdapterMap(rawMetadata);
    final rawFollowersTrend =
        data['followers_trend'] as List<dynamic>? ?? const [];
    final adaptedFollowersTrend =
        data['followerTrend'] as List<dynamic>? ?? const [];
    final latestTrend = rawFollowersTrend.isNotEmpty
        ? rawFollowersTrend.last
        : null;
    final followerCount = latestTrend?['count'] ?? 0;
    final latestTweet = data['latest_tweets'] ?? data['latestTweet'];

    return {
      'username': data['username'] ?? '',
      'profile_image': data['avatar'] ?? data['profile_image'],
      'full_name': data['fullname'] ?? data['full_name'] ?? '',
      'verified': data['verified'] ?? false,
      'followerCount': data['followerCount'] ?? followerCount,
      'smartFollowerCount':
          data['smartFollowerCount'] ?? data['verified_followers_count'] ?? 0,
      'topSmartFollowers':
          (data['topSmartFollowers'] as List<dynamic>? ??
                  data['top_followers'] as List<dynamic>? ??
                  const [])
              .map((follower) {
                return {
                  'username': follower['username'] ?? '',
                  'avatarUrl':
                      follower['avatarUrl'] ?? follower['profile_image'] ?? '',
                  'profile_image': follower['profile_image'] ?? '',
                  'full_name': follower['full_name'] ?? '',
                  'verified': follower['verified'] ?? false,
                  'followers_count': follower['followers_count'] ?? 0,
                };
              })
              .toList(),
      'followerTrend': adaptedFollowersTrend.isNotEmpty
          ? adaptedFollowersTrend
          : rawFollowersTrend.map((trend) {
              final date = DateTime.tryParse(trend['time']?.toString() ?? '');
              return {
                'date': date != null
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}'
                    : '',
                'followers': trend['count'] ?? 0,
              };
            }).toList(),
      'summary': data['summary'],
      'latestTweet': latestTweet != null
          ? {
              'text': latestTweet['text'] ?? '',
              'images': latestTweet['images'] ?? [],
              'url': latestTweet['url'] ?? '',
              'ogImage':
                  latestTweet['ogImage'] ?? latestTweet['og_image'] ?? '',
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    // return Text('TwitterCardDefinition');
    return TwitterWidget(card: params.card, size: params.size);
  }
}
