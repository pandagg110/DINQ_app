import 'package:flutter/material.dart';

// 与 TSX 一致的主题色
const Color _kAccent = Color(0xFF81A1C1);
const Color _kAccentLight = Color(0x4D81A1C1); // 30% opacity
const Color _kAccentIcon = Color(0xD981A1C1); // 85% opacity

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

/// 单步展示（与 TSX ThinkingStepItem 对应）
class _ThinkingStepItem extends StatelessWidget {
  const _ThinkingStepItem({
    required this.step,
    required this.isLast,
  });

  final Map<String, dynamic> step;
  final bool isLast;

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
                Text(
                  'Planning tasks',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
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
                                  ? Colors.green.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildToolCallStep(Map<String, dynamic> step, bool isLast, bool completed) {
    final inputType = step['inputType'] as String? ?? 'query';
    final inputs = step['inputs'] as List<dynamic>? ?? [];
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
                    color: completed ? Colors.grey[800] : Colors.grey[600],
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
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildThinkingStep(String content, bool isLast, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineLead(isLast, isDot: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: completed ? Colors.grey[800] : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ));
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getTitle(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
              const Divider(height: 1),
              ConstrainedBox(
                constraints: maxHeight != null
                    ? BoxConstraints(maxHeight: maxHeight!)
                    : const BoxConstraints(),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 12, 8),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.grey[400]),
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
