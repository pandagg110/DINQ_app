import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../message_group/assistant_narration_view.dart';
import 'deep_search_models.dart';
import 'sub_agent_helpers.dart';

const _indent = 20.0;
const _indentL2 = 28.0;

/// 与 TSX `SubAgentTracker` 主入口对齐。
class SubAgentTracker extends StatelessWidget {
  const SubAgentTracker({
    super.key,
    required this.subAgents,
    this.compactTop = false,
  });

  final Map<String, SubAgentInfo> subAgents;
  final bool compactTop;

  @override
  Widget build(BuildContext context) {
    if (subAgents.isEmpty) return const SizedBox.shrink();

    final agents = subAgents.values.toList();
    final isSingleAgent =
        agents.length == 1 && agents.first.id == virtualAgentId;

    if (isSingleAgent) {
      return SingleAgentTree(agent: agents.first, compactTop: compactTop);
    }

    final allDone = agents.every((a) => a.status == DeepSearchRoundStatus.done);
    final anyStarted = agents.any(
      (a) => a.contentBlocks.isNotEmpty || a.status == DeepSearchRoundStatus.done,
    );
    final isMultiRunning = !allDone;
    final headerText = allDone
        ? '${agents.length} Search agents finished'
        : anyStarted
            ? 'Running ${agents.length} Search agents'
            : 'Initializing Search agents';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                headerText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171717),
                  height: 1.5,
                ),
              ),
              if (isMultiRunning) const _PulsingDots(),
            ],
          ),
          const SizedBox(height: 4),
          ...agents.asMap().entries.map(
            (entry) => SourceRow(
              agent: entry.value,
              isLast: entry.key == agents.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 与 TSX `SingleAgentSummary` 对齐：候选人表格之后的 wrap-up 叙述。
class SingleAgentSummary extends StatelessWidget {
  const SingleAgentSummary({super.key, required this.subAgents});

  final Map<String, SubAgentInfo> subAgents;

  @override
  Widget build(BuildContext context) {
    final virtualAgent = subAgents[virtualAgentId];
    if (virtualAgent == null) return const SizedBox.shrink();

    final classified = classifyBlocks(
      virtualAgent.contentBlocks,
      allowFallbackSummary:
          virtualAgent.status != DeepSearchRoundStatus.searching,
    );
    final summary = classified.summary;
    if (summary == null || summary.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AssistantNarrationView(
        text: summary.text,
        blockId: summary.id,
        isStreaming: summary.isStreaming,
      ),
    );
  }
}

class SingleAgentTree extends StatefulWidget {
  const SingleAgentTree({
    super.key,
    required this.agent,
    this.compactTop = false,
  });

  final SubAgentInfo agent;
  final bool compactTop;

  @override
  State<SingleAgentTree> createState() => _SingleAgentTreeState();
}

class _SingleAgentTreeState extends State<SingleAgentTree> {
  var _userExpanded = false;

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final isDone = agent.status == DeepSearchRoundStatus.done;
    final isError = agent.status == DeepSearchRoundStatus.error;
    final isRunning = !isDone && !isError;
    final hasStarted = agent.contentBlocks.isNotEmpty || isDone;

    final toolCount = countToolCalls(agent.contentBlocks);
    final classified = classifyBlocks(
      agent.contentBlocks,
      allowFallbackSummary: !isRunning,
    );

    final isThinking = classified.initialThinking.any((b) => b.isStreaming) ||
        classified.segments.whereType<ThinkingTreeSegment>().any(
              (s) => s.blocks.any((b) => b.isStreaming),
            );

    final isSearching = isRunning && !isThinking;
    final lastToolGroupIdx = classified.segments.lastIndexWhere(
      (s) => s is ToolGroupTreeSegment,
    );

    final headerText = isDone
        ? 'Search complete'
        : isSearching
            ? null
            : isRunning
                ? 'Searching'
                : isError
                    ? 'Search failed'
                    : 'Search';

    final showTree = toolCount > 0 || classified.segments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (classified.initialThinking.isNotEmpty)
          _ThinkingBubbleView(blocks: classified.initialThinking),
        if (classified.opening != null)
          Padding(
            padding: EdgeInsets.only(top: widget.compactTop ? 4 : 0),
            child: AssistantNarrationView(
              text: classified.opening!.text,
              blockId: classified.opening!.id,
              isStreaming: classified.opening!.isStreaming,
            ),
          ),
        if (showTree) ...[
          Padding(
            padding: EdgeInsets.only(top: widget.compactTop ? 0 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _SpiralSpinner(size: 16),
                  ),
                if (headerText != null)
                  Text(
                    headerText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isRunning
                          ? const Color(0xFF6B6862)
                          : const Color(0xFF171717),
                    ),
                  )
                else if (isSearching)
                  _RotatingText(
                    messages: searchingMessages,
                    active: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6862),
                    ),
                  ),
                if (isSearching) const _PulsingDots(),
                const SizedBox(width: 8),
                Text(
                  [
                    if (toolCount > 0) '$toolCount tools',
                    if (isDone && agent.candidatesFound > 0)
                      '${agent.candidatesFound} found',
                    if (isDone && agent.durationS != null)
                      '${agent.durationS!.round()}s',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8880),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (isRunning && !hasStarted)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 20),
              child: Row(
                children: [
                  _BounceSpinner(),
                  SizedBox(width: 6),
                  Text(
                    'Initializing',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
                  ),
                ],
              ),
            ),
          if (classified.segments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Column(
                children: classified.segments.asMap().entries.map((entry) {
                  final segment = entry.value;
                  final isLast = entry.key == classified.segments.length - 1;
                  if (segment is ThinkingTreeSegment) {
                    return _ThinkingTreeNode(
                      blocks: segment.blocks,
                      isLast: isLast,
                      searchRunning: isRunning,
                    );
                  }
                  if (segment is ToolGroupTreeSegment) {
                    return _ToolGroupRow(
                      group: segment.group,
                      isLast: isLast,
                      isActive: entry.key == lastToolGroupIdx && isRunning,
                      searchRunning: isRunning,
                      userExpanded: _userExpanded,
                      onUserExpand: () => setState(() => _userExpanded = true),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }
}

class SourceRow extends StatefulWidget {
  const SourceRow({super.key, required this.agent, required this.isLast});

  final SubAgentInfo agent;
  final bool isLast;

  @override
  State<SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends State<SourceRow> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final label = sourceLabels[agent.name] ?? 'Source';
    final isDone = agent.status == DeepSearchRoundStatus.done;
    final isRunning =
        agent.status != DeepSearchRoundStatus.done &&
        agent.status != DeepSearchRoundStatus.error;

    final toolBlocks = agent.contentBlocks
        .whereType<ToolCallPart>()
        .where((p) => !isHiddenToolCall(p))
        .map((p) => p.block)
        .toList();

    ToolCallBlock? latestTool;
    for (final tool in toolBlocks) {
      if (tool.status == ToolCallStatus.running) {
        latestTool = tool;
        break;
      }
    }
    latestTool ??= toolBlocks.isNotEmpty ? toolBlocks.last : null;

    final detailBlocks = agent.contentBlocks.where((b) {
      if (isHiddenToolCall(b)) return false;
      if (b is ToolCallPart) return true;
      if (b is ReasoningPart) {
        final t = b.block.text.trim();
        if (t.isEmpty) return false;
        if (t.contains('": "') || t.contains('```') || t.contains('https://')) {
          return false;
        }
        return true;
      }
      return false;
    }).toList();

    final hasDetail = detailBlocks.isNotEmpty;
    final showInitializing = isRunning && agent.contentBlocks.isEmpty;
    final showActivity =
        isRunning && agent.contentBlocks.isNotEmpty && latestTool != null && !_expanded;

    return Padding(
      padding: EdgeInsets.only(left: _indent, bottom: widget.isLast ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasDetail ? () => setState(() => _expanded = !_expanded) : null,
            child: Row(
              children: [
                Icon(
                  _sourceIcon(agent.name),
                  size: 14,
                  color: const Color(0xFF6B6962),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone
                          ? const Color(0xFF6B6962)
                          : const Color(0xFF2A2826),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasDetail)
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                const SizedBox(width: 8),
                Text(
                  [
                    if (toolBlocks.isNotEmpty) '${toolBlocks.length} tool uses',
                    if (agent.candidatesFound > 0) '${agent.candidatesFound} found',
                    if (isDone && agent.durationS != null)
                      '${agent.durationS!.round()}s',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
                ),
              ],
            ),
          ),
          if (showInitializing)
            _SubActivityLine(text: 'Initializing…', showSpinner: true),
          if (showActivity)
            _SubActivityLine(text: toolToGerund(latestTool!.name)),
          if (_expanded)
            ...detailBlocks.map(
              (block) => Padding(
                padding: const EdgeInsets.only(left: _indentL2, top: 4),
                child: block is ToolCallPart
                    ? _ToolNodeContent(block: block.block)
                    : block is ReasoningPart
                        ? Text(
                            block.block.text.length > 150
                                ? block.block.text
                                    .substring(block.block.text.length - 150)
                                    .trim()
                                : block.block.text.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4843),
                              height: 1.45,
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _sourceIcon(String name) {
    switch (name) {
      case 'academic-search':
        return Icons.menu_book_outlined;
      case 'tech-talent-search':
        return Icons.code;
      default:
        return Icons.language;
    }
  }
}

class _ToolGroupRow extends StatefulWidget {
  const _ToolGroupRow({
    required this.group,
    required this.isLast,
    required this.isActive,
    required this.searchRunning,
    required this.userExpanded,
    required this.onUserExpand,
  });

  final ToolGroup group;
  final bool isLast;
  final bool isActive;
  final bool searchRunning;
  final bool userExpanded;
  final VoidCallback onUserExpand;

  @override
  State<_ToolGroupRow> createState() => _ToolGroupRowState();
}

class _ToolGroupRowState extends State<_ToolGroupRow> {
  var _manualCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final hasTools = group.tools.isNotEmpty;
    final label = group.label ?? fallbackToolGroupLabel(group.tools);
    final showTools =
        widget.isActive || (widget.userExpanded && !_manualCollapsed);
    final showInitializing = widget.isActive && !hasTools;
    ToolCallBlock? latestTool;
    for (final tool in group.tools) {
      if (tool.status == ToolCallStatus.running) {
        latestTool = tool;
        break;
      }
    }
    latestTool ??= group.tools.isNotEmpty ? group.tools.last : null;
    final showActivity = !showTools && hasTools && latestTool?.status == ToolCallStatus.running;

    return Padding(
      padding: const EdgeInsets.only(left: _indent, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasTools && !widget.isActive
                ? () {
                    if (!widget.userExpanded) {
                      widget.onUserExpand();
                    } else {
                      setState(() => _manualCollapsed = !_manualCollapsed);
                    }
                  }
                : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isActive
                          ? const Color(0xFF2A2826)
                          : const Color(0xFF4A4843),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!showTools && hasTools)
                  Text(
                    '${group.tools.length} tools',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
                  ),
              ],
            ),
          ),
          if (showInitializing)
            _SubActivityLine(text: 'Preparing tools…', showSpinner: true),
          if (showActivity)
            _SubActivityLine(text: toolToGerund(latestTool!.name)),
          if (showTools && hasTools)
            ...group.tools.map(
              (block) => Padding(
                padding: const EdgeInsets.only(left: _indentL2, top: 4),
                child: _ToolNodeContent(block: block),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingTreeNode extends StatelessWidget {
  const _ThinkingTreeNode({
    required this.blocks,
    required this.isLast,
    required this.searchRunning,
  });

  final List<ThinkingBlock> blocks;
  final bool isLast;
  final bool searchRunning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _indent, top: 8),
      child: _ThinkingBubbleView(blocks: blocks),
    );
  }
}

class _ThinkingBubbleView extends StatefulWidget {
  const _ThinkingBubbleView({required this.blocks});

  final List<ThinkingBlock> blocks;

  @override
  State<_ThinkingBubbleView> createState() => _ThinkingBubbleViewState();
}

class _ThinkingBubbleViewState extends State<_ThinkingBubbleView> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.blocks.isEmpty) return const SizedBox.shrink();
    final isStreaming = widget.blocks.any((b) => b.isStreaming);
    final totalText = widget.blocks.map((b) => b.text).join();
    final startedAt = widget.blocks.first.startedAt;
    final endedAt = widget.blocks.last.endedAt;
    final durationMs = !isStreaming && startedAt > 0
        ? ((endedAt ?? DateTime.now().millisecondsSinceEpoch) - startedAt)
        : null;
    final durationLabel = durationMs == null
        ? null
        : durationMs < 1000
            ? '${durationMs}ms'
            : '${(durationMs / 1000).toStringAsFixed(1)}s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_more : Icons.chevron_right,
                size: 14,
                color: const Color(0xFF9E9B93),
              ),
              if (isStreaming) ...[
                const _HalfCircleSpinner(),
                const SizedBox(width: 6),
                _RotatingText(
                  messages: thinkingMessages,
                  active: true,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E9B93)),
                ),
                const _PulsingDots(color: Color(0xFF9E9B93)),
              ] else
                Text(
                  durationLabel == null
                      ? 'Thought'
                      : 'Thought for $durationLabel',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E9B93)),
                ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: totalText,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF8A8880),
                  ),
                ),
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 150),
        ),
      ],
    );
  }
}

class _ToolNodeContent extends StatelessWidget {
  const _ToolNodeContent({required this.block});

  final ToolCallBlock block;

  @override
  Widget build(BuildContext context) {
    final toolRunning = block.status == ToolCallStatus.running;

    if (block.name.contains('submit_candidates') && !toolRunning) {
      final names = extractCandidateNames(block.input);
      final shown = names.take(5).toList();
      final rest = names.length - shown.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Submitted candidates',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA5A39E)),
                ),
              ),
              Text(
                formatDuration(block),
                style: const TextStyle(fontSize: 11, color: Color(0xFFB5B3AE)),
              ),
            ],
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...shown.map(
                  (name) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E3DE)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B6962),
                      ),
                    ),
                  ),
                ),
                if (rest > 0)
                  Text('+$rest', style: const TextStyle(fontSize: 11, color: Color(0xFFA5A39E))),
              ],
            ),
          ],
        ],
      );
    }

    final queryInfo = extractToolQuery(block.input);
    final urls =
        toolRunning ? <String>[] : extractResultUrls(block.result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: toolRunning
                          ? toolToGerund(block.name)
                          : toolToPast(block.name),
                      style: TextStyle(
                        fontSize: 12,
                        color: toolRunning
                            ? const Color(0xFF8A8880)
                            : const Color(0xFFA5A39E),
                      ),
                    ),
                    if (queryInfo.query != null) ...[
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F4F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            queryInfo.query!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B6962),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatDuration(block),
              style: const TextStyle(fontSize: 11, color: Color(0xFFB5B3AE)),
            ),
          ],
        ),
        if (urls.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: urls
                .map(
                  (url) => Text(
                    url.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA5A39E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _SubActivityLine extends StatelessWidget {
  const _SubActivityLine({required this.text, this.showSpinner = false});

  final String text;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _indentL2, top: 4),
      child: Row(
        children: [
          if (showSpinner) const _BounceSpinner(),
          if (showSpinner) const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatingText extends StatefulWidget {
  const _RotatingText({
    required this.messages,
    required this.active,
    required this.style,
  });

  final List<String> messages;
  final bool active;
  final TextStyle style;

  @override
  State<_RotatingText> createState() => _RotatingTextState();
}

class _RotatingTextState extends State<_RotatingText> {
  late String _text;
  Timer? _timer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _text = widget.messages.first;
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _RotatingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _schedule();
      } else {
        _timer?.cancel();
        _text = widget.messages.first;
      }
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.active) return;
    final delayMs = 3000 + _random.nextInt(3000);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        var next = widget.messages[_random.nextInt(widget.messages.length)];
        while (next == _text && widget.messages.length > 1) {
          next = widget.messages[_random.nextInt(widget.messages.length)];
        }
        _text = next;
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_text, style: widget.style);
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({this.color = const Color(0xFF8A8880)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text('...', style: TextStyle(fontSize: 12, color: color));
  }
}

class _BounceSpinner extends StatefulWidget {
  const _BounceSpinner();

  @override
  State<_BounceSpinner> createState() => _BounceSpinnerState();
}

class _BounceSpinnerState extends State<_BounceSpinner> {
  static const _frames = [
    '∙∙∙∙∙',
    '●∙∙∙∙',
    '∙●∙∙∙',
    '∙∙●∙∙',
    '∙∙∙●∙',
    '∙∙∙∙●',
    '∙∙∙∙∙',
  ];
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _frames[_index],
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        color: Color(0xFF8A8880),
      ),
    );
  }
}

class _HalfCircleSpinner extends StatefulWidget {
  const _HalfCircleSpinner();

  @override
  State<_HalfCircleSpinner> createState() => _HalfCircleSpinnerState();
}

class _HalfCircleSpinnerState extends State<_HalfCircleSpinner> {
  static const _frames = ['◐', '◓', '◑', '◒'];
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _frames[_index],
      style: const TextStyle(fontSize: 14, color: Color(0xFF9E9B93)),
    );
  }
}

class _SpiralSpinner extends StatefulWidget {
  const _SpiralSpinner({this.size = 16});

  final double size;

  @override
  State<_SpiralSpinner> createState() => _SpiralSpinnerState();
}

class _SpiralSpinnerState extends State<_SpiralSpinner> {
  static const _frames = [
    ['⠁', '⠀'],
    ['⠉', '⠀'],
    ['⠉', '⠁'],
    ['⠉', '⠉'],
    ['⠉', '⠙'],
    ['⠉', '⠹'],
    ['⠉', '⢹'],
    ['⠉', '⣹'],
    ['⢉', '⣹'],
    ['⣉', '⣹'],
    ['⣍', '⣹'],
    ['⣏', '⣹'],
    ['⣟', '⣹'],
    ['⣟', '⣻'],
    ['⣟', '⣿'],
    ['⣿', '⣿'],
  ];
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frames[_index];
    return Text(
      frame.join(),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: widget.size,
        color: const Color(0xFF9E9A94),
        letterSpacing: -3,
      ),
    );
  }
}
