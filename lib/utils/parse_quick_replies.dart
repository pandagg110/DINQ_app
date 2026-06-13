/// 与 TSX parseQuickReplies.ts 一致：从 assistant 文本中提取快捷回复选项
class ParsedQuickReplies {
  const ParsedQuickReplies({required this.cleanText, required this.options});

  final String cleanText;
  final List<String> options;
}

final _trailingHrRe = RegExp(r'\n+[ \t]*(?:-{3,}|\*{3,}|_{3,})[ \t]*$');

String _stripTrailingHr(String text) {
  return text.replaceAll(_trailingHrRe, '').trimRight();
}

final _patterns = <({RegExp re, RegExp separator})>[
  (re: RegExp(r'<<([\s\S]+?)>>'), separator: RegExp(r'\|')),
  (re: RegExp(r'`\[([\s\S]+?)\]`'), separator: RegExp(r',')),
  (re: RegExp(r'\*\*\[([\s\S]+?)\]\*\*'), separator: RegExp(r',')),
];

const _openers = ['<<', '`[', '**['];

ParsedQuickReplies parseQuickReplies(String text) {
  for (final pattern in _patterns) {
    final match = pattern.re.firstMatch(text);
    if (match != null) {
      final options = match
          .group(1)!
          .split(pattern.separator)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return ParsedQuickReplies(
        cleanText: _stripTrailingHr(text.replaceAll(match.group(0)!, '').trimRight()),
        options: options,
      );
    }
  }

  var earliestOpen = -1;
  for (final open in _openers) {
    final idx = text.indexOf(open);
    if (idx >= 0 && (earliestOpen < 0 || idx < earliestOpen)) {
      earliestOpen = idx;
    }
  }
  if (earliestOpen >= 0) {
    return ParsedQuickReplies(
      cleanText: _stripTrailingHr(text.substring(0, earliestOpen).trimRight()),
      options: const [],
    );
  }

  return ParsedQuickReplies(cleanText: text, options: const []);
}
