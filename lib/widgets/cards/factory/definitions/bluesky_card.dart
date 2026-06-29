import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class BlueskyCardDefinition extends CardDefinition {
  @override
  String get type => 'BLUESKY';

  @override
  String get icon => '/icons/social-icons/BlueSky.svg';

  @override
  String get name => 'Bluesky';

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
    return {
      'handle': data['handle'] ?? '',
      'display_name': data['display_name'] ?? '',
      'description': data['description'] ?? '',
      'avatar': data['avatar'] ?? '',
      'og_image': data['og_image'] ?? '',
      'followers_count': data['followers_count'] ?? 0,
      'follows_count': data['follows_count'] ?? 0,
      'posts_count': data['posts_count'] ?? 0,
      'created_at': data['created_at'] ?? '',
      'url': data['url'] ?? '',
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final data = params.card.data.metadata;
    final handle = data['handle']?.toString() ?? '';
    final displayName = data['display_name']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final ogImage = data['og_image']?.toString() ?? '';
    final followers = data['followers_count'] ?? 0;
    final following = data['follows_count'] ?? 0;
    final posts = data['posts_count'] ?? 0;

    if (handle.isEmpty && displayName.isEmpty) {
      return const SizedBox.shrink();
    }

    final size = params.size.toLowerCase();
    final metrics = [
      _Metric(label: 'Followers', value: followers),
      _Metric(label: 'Following', value: following),
      _Metric(label: 'Posts', value: posts),
    ];

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/BlueSky.svg', size: 40),
          if (size == '4x4') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: metrics.map((m) => Expanded(child: m)).toList(),
            ),
            const SizedBox(height: 12),
            if (ogImage.isNotEmpty)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ogImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              )
            else
              const Spacer(),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ] else if (size == '4x2') ...[
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: metrics.map((m) => Expanded(child: m)).toList(),
            ),
          ] else if (size == '2x4') ...[
            const Spacer(),
            ...metrics.map(
              (m) => Padding(padding: const EdgeInsets.only(top: 14), child: m),
            ),
          ] else ...[
            const Spacer(),
            _Metric(label: 'Followers', value: followers),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
