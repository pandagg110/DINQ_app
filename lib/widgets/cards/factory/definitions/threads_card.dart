import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class ThreadsCardDefinition extends CardDefinition {
  @override
  String get type => 'THREADS';

  @override
  String get icon => '/icons/social-icons/Threads.svg';

  @override
  String get name => 'Threads';

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
    final latestPost = data['latest_post'] ?? data['latestPost'];
    return {
      'name': data['name'] ?? '',
      'handle': data['handle'] ?? '',
      'avatar': data['avatar'] ?? '',
      'followerCount': data['follower_count'] ?? data['followerCount'] ?? 0,
      'latestPost': latestPost is Map
          ? {
              'url': latestPost['url'] ?? '',
              'content': latestPost['content'] ?? '',
              'coverImage':
                  latestPost['cover_image'] ?? latestPost['coverImage'] ?? '',
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final data = params.card.data.metadata;
    final name = data['name']?.toString() ?? '';
    final handle = data['handle']?.toString() ?? '';
    final avatar = data['avatar']?.toString() ?? '';
    final followers = data['followerCount'] ?? 0;
    final latestPost = data['latestPost'] is Map
        ? Map<String, dynamic>.from(data['latestPost'] as Map)
        : null;
    final coverImage = latestPost?['coverImage']?.toString() ?? '';
    final content = latestPost?['content']?.toString() ?? '';

    final size = params.size.toLowerCase();
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (size == '4x4')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AssetIcon(
                  asset: 'icons/social-icons/Threads.svg',
                  size: 40,
                ),
                _Metric(label: 'Followers', value: followers, alignEnd: true),
              ],
            )
          else
            const AssetIcon(asset: 'icons/social-icons/Threads.svg', size: 40),
          if (size == '4x4') ...[
            const SizedBox(height: 14),
            if (avatar.isNotEmpty || name.isNotEmpty || handle.isNotEmpty)
              Row(
                children: [
                  _Avatar(avatar: avatar, fallbackSize: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Identity(name: name, handle: handle),
                  ),
                ],
              ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              ),
            ],
            if (coverImage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    coverImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ] else
              const Spacer(),
          ] else if (size == '4x2') ...[
            const SizedBox(height: 10),
            _Identity(name: name, handle: handle),
            const Spacer(),
            _Metric(label: 'Followers', value: followers),
          ] else if (size == '2x4') ...[
            const SizedBox(height: 12),
            _Identity(name: name, handle: handle),
            const Spacer(),
            _Metric(label: 'Followers', value: followers),
          ] else ...[
            const Spacer(),
            _Metric(label: 'Followers', value: followers),
          ],
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.handle});

  final String name;
  final String handle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name.isNotEmpty)
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        if (handle.isNotEmpty)
          Text(
            '@$handle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.fallbackSize});

  final String avatar;
  final double fallbackSize;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: avatar.isNotEmpty
          ? Image.network(
              avatar,
              width: fallbackSize,
              height: fallbackSize,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const AssetIcon(
                asset: 'icons/social-icons/Threads.svg',
                size: 40,
              ),
            )
          : const AssetIcon(asset: 'icons/social-icons/Threads.svg', size: 40),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final dynamic value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
