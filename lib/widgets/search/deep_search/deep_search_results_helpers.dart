import 'package:flutter/material.dart';

/// 与 TSX DeepSearchResults 工具栏/操作图标路径对齐。
abstract final class DeepSearchResultsAssets {
  static const gridView = 'assets/icons/search/deep_search/grid-view.svg';
  static const listView = 'assets/icons/search/deep_search/list-view.svg';
  static const download = 'assets/icons/search/deep_search/download.svg';
  static const copy = 'assets/icons/search/copy.svg';
  static const bookmark = 'assets/icons/search/deep_search/bookmark.svg';
}

/// 与 Web `bg-page-bg` / 结果区背景一致。
abstract final class DeepSearchResultsColors {
  static const pageBg = Color(0xFFFBFBF9);
  static const scrollBg = Color(0xFFFCFBF9);
  static const toolbarBg = Color(0xFFF7F6F2);
  static const filterBg = Color(0xFFF8F7F4);
  static const border = Color(0xFFEAEAE4);
  static const divider = Color(0xFFEAE8E3);
  static const filterBorder = Color(0xFFE5E3DE);
}

const highMatchThreshold = 75;
const mediumMatchThreshold = 50;

int formatConfidence(dynamic confidence) {
  final value = confidence is num
      ? confidence.toDouble()
      : double.tryParse(confidence?.toString() ?? '') ?? 0;
  return (value.clamp(0.0, 1.0) * 100).round();
}

class MatchBadgeStyle {
  const MatchBadgeStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

MatchBadgeStyle matchBadgeStyle(int match) {
  if (match >= highMatchThreshold) {
    return const MatchBadgeStyle(
      background: Color(0xFFE5ECE7),
      foreground: Color(0xCC3B6145),
      border: Color(0x08000000),
    );
  }
  if (match >= mediumMatchThreshold) {
    return const MatchBadgeStyle(
      background: Color(0xFFEFE8DA),
      foreground: Color(0xCC635033),
      border: Color(0x08000000),
    );
  }
  return const MatchBadgeStyle(
    background: Color(0xFFEFE1E0),
    foreground: Color(0xCC6B413F),
    border: Color(0x08000000),
  );
}

class SourceCategory {
  const SourceCategory({
    required this.match,
    required this.label,
    required this.icon,
  });

  final List<String> match;
  final String label;
  final IconData icon;
}

const sourceCategories = <SourceCategory>[
  SourceCategory(
    match: ['firecrawl_search', 'brave_web_search', 'search_web'],
    label: 'Web',
    icon: Icons.language,
  ),
  SourceCategory(
    match: ['perplexity_search'],
    label: 'AI Search',
    icon: Icons.auto_awesome_outlined,
  ),
  SourceCategory(
    match: ['firecrawl_scrape'],
    label: 'Scrape',
    icon: Icons.description_outlined,
  ),
  SourceCategory(
    match: ['search_ai_lab_talent'],
    label: 'Academic',
    icon: Icons.school_outlined,
  ),
  SourceCategory(
    match: ['search_hf_users'],
    label: 'HuggingFace',
    icon: Icons.inventory_2_outlined,
  ),
  SourceCategory(
    match: ['search_github_talent'],
    label: 'GitHub',
    icon: Icons.code,
  ),
  SourceCategory(
    match: ['submit_candidates'],
    label: 'Submit',
    icon: Icons.person_add_outlined,
  ),
];

SourceCategory? findSourceCategory(String toolName) {
  for (final cat in sourceCategories) {
    if (cat.match.any(toolName.contains)) return cat;
  }
  return null;
}

String getRowSourceLabel(Map<String, dynamic> row) {
  final source = row['source']?.toString() ?? '';
  return findSourceCategory(source)?.label ?? source;
}

String toInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

const _avatarPalette = <Color>[
  Color(0xFFE8EDF5),
  Color(0xFFEDE8F5),
  Color(0xFFE8F5ED),
  Color(0xFFF5EDE8),
  Color(0xFFF5E8ED),
  Color(0xFFE8F0F5),
  Color(0xFFF0F5E8),
  Color(0xFFF5F0E8),
];

Color nameToAvatarColor(String name) {
  final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _avatarPalette[hash % _avatarPalette.length];
}

/// Tab / enrich 用的候选人结构，保留 Deep Search row 字段。
Map<String, dynamic> candidateRowToTabCandidate(Map<String, dynamic> row) {
  final map = Map<String, dynamic>.from(row);
  map['position'] ??= row['title'] ?? row['position'] ?? '';
  map['one_liner'] ??= row['evidence'] ?? row['one_liner'] ?? '';
  map['match_reason'] ??= row['evidence'] ?? '';
  return map;
}

String buildSearchResultsCsv(List<Map<String, dynamic>> rows) {
  const headers = [
    'Name',
    'Company',
    'Title',
    'Evidence',
    'Profile URL',
    'Confidence',
  ];
  final lines = <String>[headers.join(',')];
  for (final row in rows) {
    lines.add([
      _escapeCsvField(row['name']?.toString() ?? ''),
      _escapeCsvField(row['company']?.toString() ?? ''),
      _escapeCsvField(row['title']?.toString() ?? ''),
      _escapeCsvField(row['evidence']?.toString() ?? ''),
      row['profile_url']?.toString() ?? '',
      formatConfidence(row['confidence']).toString(),
    ].join(','));
  }
  return lines.join('\n');
}

String _escapeCsvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String buildSearchResultsMarkdown(List<Map<String, dynamic>> rows) {
  final buffer = StringBuffer('## Search Results\n\n');
  buffer.writeln(
    '| # | Name | Title | Company | Match | Reason | Profile |',
  );
  buffer.writeln('|---|---|---|---|---:|---|---|');
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final cells = [
      '${i + 1}',
      _escapeMdCell(row['name']),
      _escapeMdCell(row['title']),
      _escapeMdCell(row['company']),
      '${formatConfidence(row['confidence'])}%',
      _escapeMdCell(row['evidence']),
      _escapeMdCell(row['profile_url']),
    ];
    buffer.writeln('| ${cells.join(' | ')} |');
  }
  return buffer.toString();
}

String _escapeMdCell(dynamic value) {
  final text = (value?.toString() ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll('|', r'\|');
  return text.isEmpty ? '-' : text;
}

List<Map<String, dynamic>> dedupeCandidateRows(
  List<Map<String, dynamic>> rows,
) {
  final seen = <String>{};
  final deduped = <Map<String, dynamic>>[];
  for (final row in rows) {
    final rowId = row['row_id']?.toString();
    final key = (rowId != null && rowId.isNotEmpty)
        ? rowId
        : '${row['name']}|${row['company']}|${row['title']}';
    if (seen.add(key)) {
      deduped.add(row);
    }
  }
  return deduped;
}

enum DeepSearchResultsSortColumn { name, company, title, confidence }

List<Map<String, dynamic>> sortCandidateRows(
  List<Map<String, dynamic>> rows, {
  DeepSearchResultsSortColumn? column,
  bool ascending = false,
}) {
  if (column == null) return List<Map<String, dynamic>>.from(rows);
  final sorted = List<Map<String, dynamic>>.from(rows);
  sorted.sort((a, b) {
    int compare;
    switch (column) {
      case DeepSearchResultsSortColumn.confidence:
        compare = formatConfidence(a['confidence'])
            .compareTo(formatConfidence(b['confidence']));
      case DeepSearchResultsSortColumn.company:
        compare = (a['company']?.toString() ?? '')
            .compareTo(b['company']?.toString() ?? '');
      case DeepSearchResultsSortColumn.title:
        compare = (a['title']?.toString() ?? '')
            .compareTo(b['title']?.toString() ?? '');
      case DeepSearchResultsSortColumn.name:
        compare =
            (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
    }
    return ascending ? compare : -compare;
  });
  return sorted;
}
