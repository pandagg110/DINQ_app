import 'parse_quick_replies.dart';

/// 从多段 assistant 文本中选取应展示的叙述（与 TSX opening / confirm 分离逻辑对齐）
String displayAssistantText({
  required String rawText,
  required bool hasCandidates,
  required bool quickRepliesUsed,
}) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) return '';

  final parts = trimmed
      .split(RegExp(r'\n{2,}'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (parts.isEmpty) return trimmed;

  String cleanPart(String part) {
    final stripped = part
        .replaceFirst(RegExp(r'^\s*\[confirm\]\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*\\?\[summary\]\s*', caseSensitive: false), '');
    return parseQuickReplies(stripped).cleanText.trim();
  }

  if (hasCandidates || quickRepliesUsed) {
    for (var i = parts.length - 1; i >= 0; i--) {
      final parsed = parseQuickReplies(parts[i]);
      if (parsed.options.isNotEmpty) continue;
      final clean = cleanPart(parts[i]);
      if (clean.isNotEmpty) return clean;
    }
  }

  for (final part in parts) {
    final clean = cleanPart(part);
    if (clean.isNotEmpty) return clean;
  }

  return trimmed;
}
