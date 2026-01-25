import 'package:flutter/material.dart';
import '../card_definition.dart';
import 'huggingface/huggingface_widget.dart';

class HuggingFaceCardDefinition extends CardDefinition {
  @override
  String get type => 'HUGGINGFACE';

  @override
  String get icon => '/icons/logo/HuggingFace.png';

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
  Map<String, dynamic>? adapt(dynamic rawMetadata) {
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
      'username': data['username'] ?? '',
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
    return HuggingFaceWidget(
      card: params.card,
      size: params.size,
    );
  }
}

