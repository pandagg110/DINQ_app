import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class YouTubeCardDefinition extends CardDefinition {
  @override
  String get type => 'YOUTUBE';

  @override
  String get icon => '/icons/social-icons/Youtube.svg';

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
    final data = rawMetadata['data'] ?? rawMetadata;
    final video = data['representative_video'] ?? {};
    return {
      'channelId': data['channel_id'] ?? '',
      'channelName': data['channel_name'] ?? '',
      'subscriberCount': data['subscriber_count'] ?? 0,
      'viewCount': data['total_view_count'] ?? 0,
      'videoCount': data['video_count'] ?? 0,
      'videoEmbedCode': video['embed_code'] ?? '',
      'videoThumbnail': video['thumbnail'] ?? '',
      'videoTitle': video['title'] ?? '',
      'summary': data['content_summary'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final channelName = params.card.data.metadata['channelName']?.toString() ?? 'YouTube';
    final subscribers = params.card.data.metadata['subscriberCount'] ?? 0;
    final viewCount = params.card.data.metadata['viewCount'] ?? 0;
    final videoCount = params.card.data.metadata['videoCount'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Youtube.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            channelName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Subscribers: $subscribers',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (viewCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Views: $viewCount',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          if (videoCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Videos: $videoCount',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

