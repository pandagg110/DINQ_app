import 'package:flutter/material.dart';

import '../../../models/shortlist_models.dart';
import '../../../stores/shortlist_store.dart';
import '../../../theme/dinq_icons.dart';
import '../../../theme/dinq_tokens.dart';
import '../../../widgets/common/dinq_svg_icon.dart';
import '../../../widgets/search/deep_search/deep_search_results_helpers.dart';
import 'shortlist_shared_widgets.dart';

/// 对齐 `my_first_app` `_ShortlistCandidateCard`。
class ShortlistCandidateCard extends StatelessWidget {
  const ShortlistCandidateCard({
    super.key,
    required this.item,
    required this.store,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
  });

  final FavoriteItem item;
  final ShortlistStore store;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final name = item.name.isEmpty ? '—' : item.name;
    final metaLine = item.roleLine;
    final location = item.location;
    final evidence = item.evidence.trim();
    final avatarColor = nameToAvatarColor(name);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectionMode ? onToggleSelect : onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7FAFF) : DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2F6FED)
                : const Color(0xFFEAE6E0),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (selectionMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: ShortlistSelectCheckbox(
                      checked: isSelected,
                      onChanged: onToggleSelect,
                      size: ShortlistCheckboxSize.md,
                    ),
                  ),
                ],
                _CandidateAvatar(
                  name: name,
                  initials: item.initials,
                  avatarUrl: item.avatarUrl,
                  avatarColor: avatarColor,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DinqTokens.textPrimary,
                                fontSize: 15,
                                height: 20 / 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShortlistStatusBadge(status: item.status),
                        ],
                      ),
                      if (metaLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            DinqSvgIcon(
                              assetName: DinqIcons.lucideBriefcase,
                              size: 14,
                              color: const Color(0xFFC9C5BD),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                metaLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DinqTokens.textSecondary,
                                  fontSize: 12,
                                  height: 18 / 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            DinqSvgIcon(
                              assetName: DinqIcons.shortlistMapPinLight,
                              size: 14,
                              color: const Color(0xFFC9C5BD),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DinqTokens.textSecondary,
                                  fontSize: 12,
                                  height: 18 / 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (evidence.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  evidence,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF55514D),
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateAvatar extends StatelessWidget {
  const _CandidateAvatar({
    required this.name,
    required this.initials,
    required this.avatarUrl,
    required this.avatarColor,
  });

  final String name;
  final String initials;
  final String? avatarUrl;
  final Color avatarColor;

  static const double size = 68;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: avatarUrl == null
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: DinqTokens.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: DinqTokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: DinqTokens.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
