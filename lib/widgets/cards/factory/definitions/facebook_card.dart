import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

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
    final title = params.card.data.metadata['title']?.toString() ?? '';
    final pageName = params.card.data.metadata['pageName']?.toString() ?? '';
    final followers = params.card.data.metadata['followers'] ?? 0;
    final following = params.card.data.metadata['following'] ?? 0;
    final intro = params.card.data.metadata['intro']?.toString() ?? '';
    final latestPost = params.card.data.metadata['latestPost'] as Map<String, dynamic>?;
    final size = params.size;

    // 根据尺寸渲染不同的布局
    if (size == '2x2') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
            const Spacer(),
            Text(
              'Followers',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              '$followers',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (size == '2x4') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
            const SizedBox(height: 12),
            if (title.isNotEmpty || pageName.isNotEmpty) ...[
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              if (pageName.isNotEmpty)
                Text(
                  '@$pageName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              const Spacer(),
            ],
            const Spacer(),
            Text(
              'Followers',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              '$followers',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Following',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              '$following',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (size == '4x2') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      if (pageName.isNotEmpty)
                        Text(
                          '@$pageName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Followers',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      '$followers',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Following',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      '$following',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 4x4 size
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AssetIcon(asset: 'icons/social-icons/Facebook.svg', size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      if (pageName.isNotEmpty)
                        Text(
                          '@$pageName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Followers',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      Text(
                        '$followers',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Following',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      Text(
                        '$following',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (latestPost?['ogImage'] != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  latestPost!['ogImage'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (latestPost?['ogImage'] != null) const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              latestPost?['text']?.toString() ?? intro,
              style: const TextStyle(fontSize: 12, color: Color(0xFF171717)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

