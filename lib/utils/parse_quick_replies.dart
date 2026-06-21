import 'dart:convert';

/// 与 TSX parseQuickReplies.ts 一致：从 assistant 文本中提取快捷回复选项
class ParsedQuickReplies {
  const ParsedQuickReplies({required this.cleanText, required this.options});

  final String cleanText;
  final List<String> options;
}

/// 与 TSX `ParsedEnvelope` 对齐。
class ParsedEnvelope {
  const ParsedEnvelope({
    required this.type,
    required this.cleanText,
    required this.options,
  });

  final String type;
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

final _legacyKindRe = RegExp(r'^\s*\[(confirm|summary)\]\s*', caseSensitive: false);
final _legacyQuickReplyRe = RegExp(r'<<([^<>]+)>>');

ParsedEnvelope? _normalizeEnvelopeObject(dynamic parsed) {
  if (parsed is! Map) return null;
  final hasFields =
      parsed.containsKey('content') ||
      parsed.containsKey('option') ||
      parsed.containsKey('type');
  if (!hasFields) return null;

  final options = parsed['option'] is List
      ? (parsed['option'] as List)
          .map((x) => x.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList()
      : <String>[];

  return ParsedEnvelope(
    type: parsed['type']?.toString() ?? '',
    cleanText: _stripTrailingHr(parsed['content']?.toString() ?? ''),
    options: options,
  );
}

ParsedEnvelope? _parseEmbeddedSummaryEnvelope(String text) {
  var searchFrom = 0;
  while (searchFrom < text.length) {
    final start = text.indexOf('{', searchFrom);
    if (start < 0) return null;
    try {
      final parsed = _normalizeEnvelopeObject(jsonDecode(text.substring(start)));
      if (parsed?.type == 'summary') return parsed;
    } catch (_) {}
    searchFrom = start + 1;
  }
  return null;
}

ParsedEnvelope? _parseLegacyTranscript(String text) {
  final kindMatch = _legacyKindRe.firstMatch(text);
  final type = kindMatch != null ? kindMatch.group(1)!.toLowerCase() : '';
  var body = kindMatch != null ? text.substring(kindMatch.end) : text;

  final options = <String>[];
  var quickReplyStart = -1;
  for (final match in _legacyQuickReplyRe.allMatches(body)) {
    if (quickReplyStart < 0) quickReplyStart = match.start;
    options.addAll(
      match.group(1)!.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty),
    );
  }

  if (options.isNotEmpty && quickReplyStart >= 0) {
    final trailing = body.substring(quickReplyStart);
    final markerOnlyTail = trailing.replaceAll(_legacyQuickReplyRe, '').trim();
    if (markerOnlyTail.isEmpty) {
      body = body.substring(0, quickReplyStart);
    } else {
      options.clear();
    }
  }

  if (type.isEmpty && options.isEmpty) return null;
  return ParsedEnvelope(
    type: type,
    cleanText: _stripTrailingHr(body),
    options: options,
  );
}

ParsedEnvelope _recoverPartialEnvelope(String trimmed) {
  final typeMatch = RegExp(r'"type"\s*:\s*"([^"]*)"').firstMatch(trimmed);
  final contentMatch = RegExp(r'"content"\s*:\s*"([\s\S]*?)"\s*,\s*"option"')
          .firstMatch(trimmed) ??
      RegExp(r'"content"\s*:\s*"([\s\S]*?)"\s*\}\s*$').firstMatch(trimmed) ??
      RegExp(r'"content"\s*:\s*"([\s\S]*)$').firstMatch(trimmed);
  var content = contentMatch?.group(1) ?? '';
  content = content
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\"', '"')
      .replaceAll(r'\\', r'\');

  final options = <String>[];
  final optionMatch = RegExp(r'"option"\s*:\s*\[([\s\S]*?)\]').firstMatch(trimmed);
  if (optionMatch != null) {
    final re = RegExp(r'"((?:[^"\\]|\\.)*)"');
    for (final m in re.allMatches(optionMatch.group(1)!)) {
      final s = m.group(1)!.replaceAll(r'\"', '"').trim();
      if (s.isNotEmpty) options.add(s);
    }
  }

  return ParsedEnvelope(
    type: typeMatch?.group(1) ?? '',
    cleanText: _stripTrailingHr(content),
    options: options,
  );
}

String _serializeParsedEnvelope(ParsedEnvelope parsed) {
  final prefix = parsed.type == 'summary' || parsed.type == 'confirm'
      ? '[${parsed.type}] '
      : '';
  final options =
      parsed.options.isNotEmpty ? '\n<<${parsed.options.join(' | ')}>>' : '';
  return '$prefix${parsed.cleanText}$options';
}

/// 与 TSX `parseEnvelope` 对齐。
ParsedEnvelope parseEnvelope(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('{')) {
    try {
      final parsed = _normalizeEnvelopeObject(jsonDecode(trimmed));
      if (parsed != null) return parsed;
    } catch (_) {
      return _recoverPartialEnvelope(trimmed);
    }
  }

  final legacy = _parseLegacyTranscript(text);
  if (legacy != null) return legacy;

  final embeddedSummary = _parseEmbeddedSummaryEnvelope(text);
  if (embeddedSummary != null) return embeddedSummary;

  return ParsedEnvelope(
    type: '',
    cleanText: _stripTrailingHr(text),
    options: const [],
  );
}

/// 与 TSX `normalizeAssistantTextContent` 对齐。
String normalizeAssistantTextContent(dynamic content) {
  if (content is String) return content;
  final parsed = _normalizeEnvelopeObject(content);
  if (parsed != null) return _serializeParsedEnvelope(parsed);
  if (content != null && (content is Map || content is List)) {
    try {
      return jsonEncode(content);
    } catch (_) {
      return '';
    }
  }
  return '';
}
