import 'package:flutter/material.dart';
import 'behance_layouts.dart';

class BehanceWidget extends StatelessWidget {
  const BehanceWidget({
    super.key,
    required this.card,
    required this.size,
  });

  final dynamic card;
  final String size;

  @override
  Widget build(BuildContext context) {
    final metadata = card.data.metadata;
    final followers = (metadata['followers'] as num?)?.toInt() ?? (metadata['followers_count'] as num?)?.toInt() ?? 0;
    final views = (metadata['views'] as num?)?.toInt() ?? (metadata['project_views'] as num?)?.toInt() ?? 0;
    final likes = (metadata['likes'] as num?)?.toInt() ?? (metadata['appreciations'] as num?)?.toInt() ?? 0;
    
    // Handle newest_work or latest_projects
    final newestWork = metadata['newest_work'] as Map<String, dynamic>?;
    final latestProjects = metadata['latest_projects'] as List<dynamic>? ?? [];
    
    Map<String, dynamic>? firstProject;
    if (newestWork != null) {
      firstProject = {
        'name': newestWork['title'] ?? '',
        'cover': newestWork['image'] ?? '',
        'url': newestWork['url'] ?? '',
      };
    } else if (latestProjects.isNotEmpty) {
      firstProject = latestProjects[0] as Map<String, dynamic>?;
    }

    switch (size) {
      case '2x2':
        return BehanceLayouts.build2x2Layout(
          followers: followers,
        );
      case '2x4':
        return BehanceLayouts.build2x4Layout(
          followers: followers,
          views: views,
          likes: likes,
        );
      case '4x2':
        return BehanceLayouts.build4x2Layout(
          followers: followers,
          views: views,
          likes: likes,
        );
      case '4x4':
        return BehanceLayouts.build4x4Layout(
          followers: followers,
          views: views,
          likes: likes,
          firstProject: firstProject,
        );
      default:
        return const Center(child: Text('Unknown size'));
    }
  }
}

