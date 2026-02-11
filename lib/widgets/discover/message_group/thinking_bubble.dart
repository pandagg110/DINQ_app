import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';

// 与 TSX 一致的主题色（只保留移动端样式）
const Color _kAccent = Color(0xFF81A1C1);
const Color _kAccentLight = Color(0x4D81A1C1); // 30% opacity
const Color _kAccentIcon = Color(0xD981A1C1); // 85% opacity
const Color _kBorderGray100 = Color(0xFFF3F4F6);
const Color _kBorderGray50 = Color(0xFFF9FAFB);
const Color _kTextGray500 = Color(0xFF6B7280);
const Color _kTextGray400 = Color(0xFF9CA3AF);
const Color _kTextGray800 = Color(0xFF1F2937);

/// 判断是否为网址（与 TSX isUrl 一致）
bool _isUrl(String? s) {
  if (s == null || s.isEmpty) return false;
  return s.startsWith('http://') || s.startsWith('https://');
}

/// 从网址提取域名（与 TSX getDomainFromUrl 一致）
String _getDomainFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host;
    return host.startsWith('www.') ? host.substring(4) : host;
  } catch (_) {
    return url;
  }
}

/// 按域名分组（与 TSX groupByDomain 一致）
Map<String, List<Map<String, dynamic>>> _groupByDomain(List<Map<String, dynamic>> sources) {
  final acc = <String, List<Map<String, dynamic>>>{};
  for (final s in sources) {
    final url = s['url'] as String? ?? '';
    final domain = _getDomainFromUrl(url);
    acc.putIfAbsent(domain, () => []).add(s);
  }
  return acc;
}

/// 获取当前步骤展示文案（与 TSX getStepDisplayText 一致）
String _getStepDisplayText(Map<String, dynamic>? step) {
  if (step == null) return 'Thinking...';
  final type = step['type'] as String?;
  if (type == 'tool_call') {
    final inputType = step['inputType'] as String? ?? 'query';
    if (inputType == 'file') return 'Reading results';
    if (inputType == 'query') return 'Searching';
    if (inputType == 'url') return 'Fetching';
    return 'Processing';
  }
  if (type == 'todo') return 'Planning tasks';
  final content = step['content'] as String? ?? '';
  if (content == 'Starting search...') return 'Thinking...';
  if (content.trim().isEmpty) return 'Thinking...';
  return content.length > 60 ? '${content.substring(0, 60)}...' : content;
}

/// 移动端：按域名分组的来源标签（无浮层，仅展示 domain + count）
class _GroupedSourceTags extends StatelessWidget {
  const _GroupedSourceTags({required this.sources});

  final List<Map<String, dynamic>> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final grouped = _groupByDomain(sources);
    final domains = grouped.keys.toList();
    final visible = domains.take(6).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: visible.map((domain) {
        final list = grouped[domain]!;
        final count = list.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                domain,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kTextGray500,
                ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '+${count - 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextGray400,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 单步展示（与 TSX ThinkingStepItem 对应，只保留移动端样式）
class _ThinkingStepItem extends StatelessWidget {
  const _ThinkingStepItem({
    required this.step,
    required this.isLast,
  });

  final Map<String, dynamic> step;
  final bool isLast;

  List<Map<String, dynamic>> get _urlSources {
    final sources = step['sources'] as List<dynamic>? ?? [];
    return sources
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((s) => _isUrl(s['url'] as String?))
        .toList();
  }

  bool get _hasDbSource {
    final sources = step['sources'] as List<dynamic>? ?? [];
    return sources.any((e) {
      if (e is! Map) return false;
      final m = Map<String, dynamic>.from(e);
      final url = m['url'] as String?;
      final desc = m['description'] as String?;
      return url == 'DINQ DB' || desc == 'DINQ DB';
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = step['type'] as String? ?? 'thinking';
    final content = step['content'] as String? ?? '';
    final completed = step['completed'] == true;

    if (type == 'todo') {
      return _buildTodoStep(content, isLast);
    }
    if (type == 'tool_call') {
      return _buildToolCallStep(step, isLast, completed);
    }
    return _buildThinkingStep(content, isLast, completed);
  }

  Widget _buildTodoStep(String content, bool isLast) {
    final todos = _parseTodos(content);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineLead(isLast, icon: _TodoIcon()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Planning tasks',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kTextGray800,
                    ),
                  ),
                  if (todos.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...todos.take(5).map((t) {
                      final status = t['status'] as String? ?? '';
                      final text = t['content'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: status == 'completed'
                                    ? Colors.green.shade600.withOpacity(0.7)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextGray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (todos.length > 5)
                      Text(
                        '+${todos.length - 5} more',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextGray400,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCallStep(Map<String, dynamic> step, bool isLast, bool completed) {
    final inputType = step['inputType'] as String? ?? 'query';
    final inputs = step['inputs'] as List<dynamic>? ?? [];
    final urlSources = _urlSources;
    String label;
    Widget icon;
    if (inputType == 'file') {
      label = completed ? 'Read results' : 'Reading results';
      icon = const _FileIcon();
    } else if (inputType == 'query') {
      label = completed ? 'Searched' : 'Searching';
      icon = const _SearchIcon();
    } else if (inputType == 'url') {
      label = completed ? 'Fetched' : 'Fetching';
      icon = const _ScrapeIcon();
    } else {
      label = completed ? 'Processed' : 'Processing';
      icon = const _ScrapeIcon();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineLead(isLast, icon: icon),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: completed ? _kTextGray800 : _kTextGray500,
                    ),
                  ),
                  if (inputs.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: inputs.map<Widget>((e) {
                        final s = e.toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (urlSources.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _GroupedSourceTags(sources: urlSources),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingStep(String content, bool isLast, bool completed) {
    final urlSources = _urlSources;
    final hasDbSource = _hasDbSource;
    final textColor = completed ? _kTextGray800 : _kTextGray500;
    final baseStyle = TextStyle(
      fontSize: 14,
      color: textColor,
      height: 1.4,
      fontFamilyFallback: AppTheme.emojiFontFallback,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineLead(isLast, isDot: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: content,
                    styleSheet: MarkdownStyleSheet(
                      p: baseStyle,
                      pPadding: const EdgeInsets.only(bottom: 4, top: 4),
                      strong: baseStyle.copyWith(fontWeight: FontWeight.w600),
                      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
                      code: baseStyle.copyWith(
                        fontSize: 12,
                        backgroundColor: Colors.grey.shade100,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      codeblockPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      a: baseStyle.copyWith(
                        color: const Color(0xFF2563EB),
                        decoration: TextDecoration.underline,
                      ),
                      listBullet: baseStyle,
                      listIndent: 24,
                      blockquote: baseStyle,
                      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade400, width: 4),
                        ),
                      ),
                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      ),
                      tableHead: baseStyle.copyWith(fontWeight: FontWeight.w600),
                      tableBody: baseStyle,
                      tableBorder: TableBorder.all(color: Colors.grey.shade300),
                      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      tableColumnWidth: const FlexColumnWidth(),
                      del: baseStyle.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: _kTextGray500,
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null && href.isNotEmpty) {
                        launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  if (hasDbSource) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storage_outlined, size: 16, color: _kAccentIcon),
                        const SizedBox(width: 6),
                        const Text(
                          'DINQ DB',
                          style: TextStyle(
                            fontSize: 14,
                            color: _kTextGray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (urlSources.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _GroupedSourceTags(sources: urlSources),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineLead(bool isLast, {Widget? icon, bool isDot = false}) {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Center(
              child: isDot
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kAccent.withOpacity(0.8),
                      ),
                    )
                  : icon ?? const SizedBox.shrink(),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 1,
                color: _kAccentLight,
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseTodos(String input) {
    try {
      final match = RegExp(r'\[[\s\S]*\]').firstMatch(input);
      if (match == null) return [];
      var jsonStr = match.group(0)!.replaceAll("'", '"');
      final list = _parseJsonList(jsonStr);
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  List<dynamic>? _parseJsonList(String s) {
    try {
      final decoded = _jsonDecodeList(s);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? _jsonDecodeList(String s) {
    final list = <dynamic>[];
    var i = 0;
    while (i < s.length) {
      final idx = s.indexOf('{', i);
      if (idx < 0) break;
      var depth = 1;
      var j = idx + 1;
      while (j < s.length && depth > 0) {
        if (s[j] == '{') depth++;
        if (s[j] == '}') depth--;
        j++;
      }
      if (depth != 0) break;
      final chunk = s.substring(idx, j);
      final map = _parseMap(chunk);
      if (map != null) list.add(map);
      i = j;
    }
    return list.isEmpty ? null : list;
  }

  Map<String, dynamic>? _parseMap(String s) {
    final map = <String, dynamic>{};
    final contentMatch = RegExp(r'"content"\s*:\s*"([^"]*)"').firstMatch(s);
    final statusMatch = RegExp(r'"status"\s*:\s*"([^"]*)"').firstMatch(s);
    if (contentMatch != null) map['content'] = contentMatch.group(1);
    if (statusMatch != null) map['status'] = statusMatch.group(1);
    return map.isEmpty ? null : map;
  }
}

// 图标组件（与 TSX 一致）
class _TodoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.check_circle_outline, size: 16, color: _kAccentIcon);
  }
}

class _SearchIcon extends StatelessWidget {
  const _SearchIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.search, size: 16, color: _kAccentIcon);
  }
}

class _ScrapeIcon extends StatelessWidget {
  const _ScrapeIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.link, size: 16, color: _kAccentIcon);
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.insert_drive_file_outlined, size: 16, color: _kAccentIcon);
  }
}

/// 与 TSX ThinkingBubble 对应：样式与结构一致
class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({
    super.key,
    required this.steps,
    required this.expanded,
    required this.loading,
    required this.onToggle,
    this.maxHeight,
    this.title,
  });

  final List<Map<String, dynamic>> steps;
  final bool expanded;
  final bool loading;
  final VoidCallback onToggle;
  /// 展开内容最大高度（与 TSX maxHeight 一致）
  final double? maxHeight;
  /// 自定义标题（与 TSX title 一致）
  final String? title;

  @override
  Widget build(BuildContext context) {
    final displaySteps = steps
        .where((s) => (s['content'] as String? ?? '') != 'Starting search...')
        .toList();
    final completedCount = displaySteps
        .where((s) {
          final completed = s['completed'] == true;
          final type = s['type'] as String?;
          final action = s['action'] as String?;
          return completed && type != 'todo' && action != 'write_todos';
        })
        .length;
    Map<String, dynamic>? currentStep;
    for (final s in displaySteps) {
      if (s['completed'] != true) {
        currentStep = s;
        break;
      }
    }
    currentStep ??= displaySteps.isEmpty ? null : displaySteps.last;

    String getTitle() {
      if (loading) return _getStepDisplayText(currentStep);
      if (title != null && title!.isNotEmpty) return '$title ($completedCount steps)';
      return 'Reasoning ($completedCount steps)';
    }

    // 与 TSX 一致：border border-gray-100 rounded-lg，只保留移动端样式
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorderGray100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部：flex items-center gap-2 text-sm text-gray-500 w-full px-3 py-2
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 16,
                        color: _kTextGray500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getTitle(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: _kTextGray500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded && displaySteps.isNotEmpty) ...[
              // 展开区：border-t border-gray-50，px-3 pb-3 pt-2
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorderGray50, width: 1)),
                ),
                child: ConstrainedBox(
                  constraints: maxHeight != null
                      ? BoxConstraints(maxHeight: maxHeight!)
                      : const BoxConstraints(),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...displaySteps.asMap().entries.map((e) {
                            return _ThinkingStepItem(
                              step: e.value,
                              isLast: e.key == displaySteps.length - 1,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 底部收起按钮：pt-2 mt-2，ChevronUp w-5 h-5 text-gray-400
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 20,
                        color: _kTextGray400,
                      ),
                    ),
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
