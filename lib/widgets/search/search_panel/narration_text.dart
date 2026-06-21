import '../../../utils/parse_quick_replies.dart';
import '../deep_search/sub_agent_helpers.dart';

/// 与 TSX `SearchPanel.cleanAssistantText` / `NarrationBlockView` 对齐。
String cleanNarrationDisplayText(String rawText) {
  final envelope = parseEnvelope(rawText);
  if (envelope.type == 'confirm' || envelope.type == 'summary') {
    return envelope.cleanText.trim();
  }

  final withoutConfirm = rawText.replaceFirst(
    RegExp(r'^\s*\[confirm\]\s*', caseSensitive: false),
    '',
  );
  final displayText = stripSummaryPrefix(withoutConfirm);
  final parsed = parseEnvelope(displayText);
  var cleanText = parsed.cleanText;

  if (parsed.options.isNotEmpty) {
    final paragraphs = cleanText
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (paragraphs.length >= 3 &&
        RegExp(r'[?？]\s*$').hasMatch(paragraphs.last)) {
      paragraphs.removeLast();
      cleanText = paragraphs.join('\n\n');
    }
  }

  return cleanText.trim();
}

/// 与 TSX `ConfirmBlock.splitConfirmContent` 对齐。
({String intro, String textareaBody}) splitConfirmContent(String body) {
  final paragraphs = body
      .split(RegExp(r'\n{2,}'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (paragraphs.isEmpty) return (intro: '', textareaBody: '');
  if (paragraphs.length == 1) return (intro: '', textareaBody: paragraphs.first);
  final intro = paragraphs.first;
  final last = paragraphs.last;
  final dropLast =
      paragraphs.length >= 3 && RegExp(r'[?？]\s*$').hasMatch(last);
  final middles = dropLast ? paragraphs.sublist(1, paragraphs.length - 1) : paragraphs.sublist(1);
  return (intro: intro, textareaBody: middles.join('\n\n'));
}
