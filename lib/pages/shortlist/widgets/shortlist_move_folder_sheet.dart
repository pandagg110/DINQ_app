import 'package:flutter/material.dart';

import '../../../models/shortlist_models.dart';
import '../shortlist_strings.dart';

/// 对齐 Web 批量移动 `AdaptiveModal`（move folder sheet）。
Future<FavoriteProject?> showShortlistMoveFolderSheet(
  BuildContext context, {
  required String currentFolderName,
  required int selectedCount,
  required List<FavoriteProject> targetProjects,
}) {
  return showModalBottomSheet<FavoriteProject>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          16 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ShortlistStrings.moveFolderTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F4F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAE8E3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 16,
                    color: Color(0xFFB5B3AE),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentFolderName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A8880),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ShortlistStrings.moveFolderCurrentFolder,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A8880),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ShortlistStrings.moveFolderPrompt(selectedCount),
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B6962)),
            ),
            const SizedBox(height: 12),
            if (targetProjects.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFEAE8E3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  ShortlistStrings.moveFolderNoOtherFolders,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8880),
                  ),
                ),
              )
            else
              ...targetProjects.map(
                (project) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, project),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEAE8E3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.folder_open_outlined,
                              size: 16,
                              color: Color(0xFFB5B3AE),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                project.isDefault
                                    ? ShortlistStrings.foldersDefaultName
                                    : project.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171717),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
