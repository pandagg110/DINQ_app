import 'package:flutter/material.dart';

import '../../../models/shortlist_models.dart';
import '../../../services/shortlist_service.dart';

/// 对齐 Web `ShortlistFolderModal` 的文件夹选择。
Future<String?> showShortlistFolderModal(BuildContext context) async {
  final service = ShortlistService();
  List<FavoriteProject> projects;
  try {
    projects = await service.listProjects();
  } catch (_) {
    projects = const [];
  }
  if (!context.mounted) return null;
  if (projects.isEmpty) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shortlist'),
        content: const Text('No folders available.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Add to folder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2826),
                ),
              ),
            ),
            for (final project in projects)
              ListTile(
                title: Text(project.name),
                subtitle: Text('${project.talentCount} talents'),
                onTap: () => Navigator.pop(ctx, project.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
