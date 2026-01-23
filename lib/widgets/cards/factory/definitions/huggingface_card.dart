import 'package:flutter/material.dart';
import '../../../common/asset_icon.dart';
import '../card_definition.dart';

class HuggingFaceCardDefinition extends CardDefinition {
  @override
  String get type => 'HUGGINGFACE';

  @override
  String get icon => '/icons/social-icons/HuggingFace.svg';

  @override
  String get name => 'Hugging Face';

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
  Map<String, dynamic>? adapt(Map<String, dynamic> rawMetadata) {
    final data = rawMetadata['data'] ?? rawMetadata;
    final orgs = data['orgs'] as List<dynamic>? ?? [];
    final topOrgs = orgs.take(4).map((org) {
      final orgMap = org as Map<String, dynamic>;
      return {
        'avatarUrl': orgMap['avatarUrl'] ?? '',
      };
    }).toList();

    String getRelativeTime(String dateString) {
      try {
        final date = DateTime.parse(dateString);
        final now = DateTime.now();
        final diffInDays = now.difference(date).inDays;

        if (diffInDays == 0) return 'today';
        if (diffInDays == 1) return 'yesterday';
        if (diffInDays < 7) return '$diffInDays days ago';
        if (diffInDays < 30) return '${(diffInDays / 7).floor()} weeks ago';
        if (diffInDays < 365) return '${(diffInDays / 30).floor()} months ago';
        return '${(diffInDays / 365).floor()} years ago';
      } catch (e) {
        return '';
      }
    }

    final bioTitle = 'AI ML Interests';
    final bioContent = data['details']?.toString() ??
        'Passionate about advancing AI and machine learning research.';

    Map<String, dynamic>? featuredRepo;
    if (data['representative_work'] != null) {
      final work = data['representative_work'] as Map<String, dynamic>;
      featuredRepo = {
        'type': work['type'] ?? '',
        'name': work['id'] ?? '',
        'description': work['description'] ?? '',
        'downloads': work['downloads'] ?? 0,
        'likes': work['likes'] ?? 0,
        'updatedAt': getRelativeTime(work['createdAt']?.toString() ?? ''),
      };
    }

    return {
      'fullname': data['fullname'] ?? '',
      'avatarUrl': data['avatarUrl'] ?? '',
      'metrics': {
        'models': data['numModels'] ?? 0,
        'datasets': data['numDatasets'] ?? 0,
        'spaces': data['numSpaces'] ?? 0,
        'papers': data['numPapers'] ?? 0,
        'followers': data['numFollowers'] ?? 0,
        'following': data['numFollowing'] ?? 0,
      },
      'organizations': topOrgs,
      'organizationCount': orgs.length,
      'bioTitle': bioTitle,
      'bioContent': bioContent,
      'featuredRepo': featuredRepo,
    };
  }

  @override
  Widget render(CardRenderParams params) {
    final fullname = params.card.data.metadata['fullname']?.toString() ?? 'Hugging Face';
    final metrics = params.card.data.metadata['metrics'] as Map<String, dynamic>?;
    final models = metrics?['models'] ?? 0;
    final datasets = metrics?['datasets'] ?? 0;
    final followers = metrics?['followers'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/HuggingFace.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            fullname,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (models > 0)
            Text(
              'Models: $models',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          if (datasets > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Datasets: $datasets',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
          if (followers > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Followers: $followers',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

