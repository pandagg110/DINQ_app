import '../agentic_search_logic.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/deep_search_results_helpers.dart';
import 'result_entry_card.dart';

/// 与 TSX `AgenticChat` mergedResultData 对齐。
class MergedResultSourceGroupData {
  const MergedResultSourceGroupData({
    required this.candidates,
    this.sourceGroupsByRowId,
    this.pendingSourceGroups,
    this.isSearching = false,
    this.isInterrupted = false,
  });

  final List<Map<String, dynamic>> candidates;
  final Map<String, ResultSourceGroup>? sourceGroupsByRowId;
  final List<ResultSourceGroup>? pendingSourceGroups;
  final bool isSearching;
  final bool isInterrupted;
}

List<AgenticMessageGroup> resultWorkspaceGroups(List<AgenticMessageGroup> groups) {
  return groups.where((group) {
    final status = groupRoundStatus(group);
    return groupHasResultWorkspace(
      group,
      isSearching: status == DeepSearchRoundStatus.searching,
    );
  }).toList();
}

String stripMarkdownForRoundTitle(String text) {
  return text
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
      .replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), r'$1')
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
      .replaceAll(RegExp(r'[*_~#>`]'), '')
      .replaceAll(RegExp(r'^\s*[-+]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String getConfirmTitleFromGroup(AgenticMessageGroup group) {
  final blocks = [
    ...group.contentBlocks,
    ...group.subAgents.values.expand((agent) => agent.contentBlocks),
  ];
  for (var i = blocks.length - 1; i >= 0; i--) {
    final part = blocks[i];
    if (part is! ReasoningPart) continue;
    final text = part.block.text;
    if (!RegExp(r'^\s*\[confirm\]', caseSensitive: false).hasMatch(text)) {
      continue;
    }
    final title = stripMarkdownForRoundTitle(
      text.replaceFirst(
        RegExp(r'^\s*\[confirm\]\s*', caseSensitive: false),
        '',
      ),
    );
    if (title.isNotEmpty) return title;
  }
  return '';
}

String getRoundTitleForGroup(
  AgenticMessageGroup group,
  List<AgenticMessageGroup> allGroups,
) {
  final defaultTitle = (group.displayQuery ?? group.userQuery).trim();
  if (isStartSearchMarker(defaultTitle)) {
    final index = allGroups.indexWhere((item) => item.id == group.id);
    if (index > 0) {
      final confirmTitle = getConfirmTitleFromGroup(allGroups[index - 1]);
      if (confirmTitle.isNotEmpty) return confirmTitle;
    }
  }
  return stripMarkdownForRoundTitle(defaultTitle).isEmpty
      ? 'Search results'
      : stripMarkdownForRoundTitle(defaultTitle);
}

/// 多轮结果合并时的 Source Group 映射；单轮时返回 null。
MergedResultSourceGroupData? buildMergedResultSourceGroups(
  List<AgenticMessageGroup> groups,
) {
  final resultGroups = resultWorkspaceGroups(groups);
  if (resultGroups.length <= 1) return null;

  final candidates = <Map<String, dynamic>>[];
  final sourceGroupsByRowId = <String, ResultSourceGroup>{};
  final pendingSourceGroups = <ResultSourceGroup>[];

  for (var i = 0; i < resultGroups.length; i++) {
    final group = resultGroups[i];
    final sourceGroup = ResultSourceGroup(
      index: i + 1,
      title: getRoundTitleForGroup(group, groups),
      count: group.candidates.length,
    );
    final status = groupRoundStatus(group);
    if (status == DeepSearchRoundStatus.searching &&
        group.candidates.isEmpty) {
      pendingSourceGroups.add(sourceGroup);
    }
    for (final row in group.candidates) {
      final rowId = row['row_id']?.toString() ?? '';
      final dedupeKey = rowId.isNotEmpty ? rowId : '${group.id}:$rowId';
      final existingIndex = candidates.indexWhere(
        (existing) => existing['row_id']?.toString() == dedupeKey,
      );
      if (existingIndex >= 0) {
        final mergedId = '${group.id}:$rowId';
        candidates[existingIndex] = {
          ...row,
          'row_id': mergedId,
        };
        sourceGroupsByRowId[mergedId] = sourceGroup;
      } else {
        final nextRow = Map<String, dynamic>.from(row);
        if (rowId.isNotEmpty &&
            candidates.any((c) => c['row_id']?.toString() == rowId)) {
          nextRow['row_id'] = '${group.id}:$rowId';
        }
        final finalId = nextRow['row_id']?.toString() ?? '';
        candidates.add(nextRow);
        if (finalId.isNotEmpty) {
          sourceGroupsByRowId[finalId] = sourceGroup;
        }
      }
    }
  }

  final isSearching = resultGroups.any(
    (g) => groupRoundStatus(g) == DeepSearchRoundStatus.searching,
  );
  final isInterrupted = resultGroups.any(
    (g) => groupRoundStatus(g) == DeepSearchRoundStatus.interrupted,
  );

  return MergedResultSourceGroupData(
    candidates: candidates,
    sourceGroupsByRowId: sourceGroupsByRowId,
    pendingSourceGroups: pendingSourceGroups,
    isSearching: isSearching,
    isInterrupted: isInterrupted,
  );
}
