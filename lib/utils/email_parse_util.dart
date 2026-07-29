// 邮箱解析工具：兼容 API / 缓存返回 string、List、嵌套 List，
// 以及 Dart List.toString() 产生的 `["a@b.com"]` 格式。

String _stripQuotes(String s) =>
    s.trim().replaceAll(RegExp(r'''^["']+|["']+$'''), '');

/// 将任意 email 载荷展平为纯邮箱字符串列表。
List<String> flattenEmailValues(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw.expand(flattenEmailValues).toList();
  }
  final text = raw.toString().trim();
  if (text.isEmpty) return [];
  // List.toString() 或 JSON 数组字符串
  if (text.startsWith('[') && text.endsWith(']')) {
    final inner = text.substring(1, text.length - 1).trim();
    if (inner.isEmpty) return [];
    return inner
        .split(RegExp(r'[,;]+'))
        .map(_stripQuotes)
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return [_stripQuotes(text)];
}

/// 对齐 Web `EnrichProfileView.tsx` parseEmails。
List<String> parseEmails(String raw) {
  return flattenEmailValues(raw)
      .expand((e) => e.split(RegExp(r'[,;\s]+')))
      .map(_stripQuotes)
      .where((e) => e.isNotEmpty)
      .toList();
}

/// 多个邮箱合并为逗号分隔字符串；无有效邮箱时返回 null。
String? joinEmails(dynamic raw) {
  final parts = flattenEmailValues(raw);
  if (parts.isEmpty) return null;
  return parts.join(', ');
}
