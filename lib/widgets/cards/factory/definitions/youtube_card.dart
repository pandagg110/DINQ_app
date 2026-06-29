import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'youtube/youtube_widget.dart';

class YouTubeCardDefinition extends CardDefinition {
  @override
  String get type => 'YOUTUBE';

  @override
  String get icon => '/icons/logo/Youtube.png';

  @override
  String get name => 'YouTube';

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
    final video = data['representative_video'] ?? {};
    return {
      'channelId': data['channelId'] ?? data['channel_id'] ?? '',
      'channelName': data['channelName'] ?? data['channel_name'] ?? '',
      'subscriberCount':
          data['subscriberCount'] ?? data['subscriber_count'] ?? 0,
      'viewCount': data['viewCount'] ?? data['total_view_count'] ?? 0,
      'videoCount': data['videoCount'] ?? data['video_count'] ?? 0,
      'videoEmbedCode': data['videoEmbedCode'] ?? video['embed_code'] ?? '',
      'videoThumbnail': data['videoThumbnail'] ?? video['thumbnail'] ?? '',
      'videoTitle': data['videoTitle'] ?? video['title'] ?? '',
      'summary': data['summary'] ?? data['content_summary'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    return YouTubeWidget(card: params.card, size: params.size);
  }
}
