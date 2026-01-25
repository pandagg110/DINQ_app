import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class InstagramCardDefinition extends CardDefinition {
  @override
  String get type => 'INSTAGRAM';

  @override
  String get icon => '/icons/social-icons/Instagram.svg';

  @override
  String get name => 'Instagram';

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
    final followersTrend = data['followers_trend'] as List<dynamic>? ?? [];
    final latestTrend = followersTrend.isNotEmpty ? followersTrend.last : null;

    return {
      'username': data['username'] ?? '',
      'profile_image': data['avatar'] ?? data['profile_image'],
      'full_name': data['fullname'] ?? data['full_name'] ?? '',
      'verified': data['verified'] ?? false,
      'followerCount': latestTrend?['count'] ?? 0,
      'smartFollowerCount': data['verified_followers_count'] ?? 0,
      'topSmartFollowers': (data['top_followers'] as List<dynamic>? ?? []).map((follower) {
        return {
          'username': follower['username'] ?? '',
          'avatarUrl': follower['profile_pic_url'] ?? '',
          'profile_image': follower['profile_pic_url'] ?? '',
          'full_name': follower['full_name'] ?? '',
          'verified': follower['verified'] ?? false,
        };
      }).toList(),
      'followerTrend': followersTrend.map((trend) {
        final date = DateTime.tryParse(trend['time']?.toString() ?? '');
        return {
          'date': date != null ? '${date.year}-${date.month.toString().padLeft(2, '0')}' : '',
          'followers': trend['count'] ?? 0,
        };
      }).toList(),
      'summary': data['summary'],
      'latestPost': data['latest_post'] != null
          ? {
              'text': data['latest_post']['caption'] ?? '',
              'images': <String>[],
              'url': data['latest_post']['url'] ?? '',
              'ogImage': data['latest_post']['og_image'] ?? '',
            }
          : null,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final username = params.card.data.metadata['username']?.toString() ?? '';
    final followerCount = params.card.data.metadata['followerCount'] ?? 0;
    final verified = params.card.data.metadata['verified'] ?? false;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AssetIcon(asset: 'icons/social-icons/Instagram.svg', size: 32),
              if (verified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 16, color: Colors.purple),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            username.isNotEmpty ? '@$username' : 'Instagram',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Followers: $followerCount',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

