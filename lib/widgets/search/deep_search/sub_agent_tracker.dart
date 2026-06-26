import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../search_panel/phase_timeline.dart';
import 'deep_search_models.dart';
import 'sub_agent_helpers.dart';
import 'trace_strings.dart';

import 'sub_agent_tree_lines.dart';

const _indent = treeIndent;
const _indentL2 = treeIndentL2;
const _l2LineLeft = treeL2LineLeft;

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
      return SingleAgentTree(
        agent: agents.first,
        compactTop: compactTop,
      );
    }

    final allDone = agents.every((a) => a.status == DeepSearchRoundStatus.done);
    final anyStarted = agents.any(
      (a) => a.contentBlocks.isNotEmpty || a.status == DeepSearchRoundStatus.done,
    );
    final isMultiRunning = !allDone;
    final headerText = allDone
        ? TraceStrings.multiFinished(agents.length)
        : anyStarted
            ? TraceStrings.multiRunning(agents.length)
            : TraceStrings.multiInitializing;

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
    if (summary == null) return const SizedBox.shrink();

    // Web: `return <NarrationBlockView block={summary} isSummary />` — no wrapper padding.
    return NarrationBlockView(block: summary, isSummary: true);
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
  var _chainCollapsed = false;
  var _chainAutoScroll = true;
  var _chainMaskTop = false;
  var _chainMaskBottom = false;
  final _chainScrollController = ScrollController();
  String _lastSegmentsSignature = '';
  DeepSearchRoundStatus? _prevStatus;

  @override
  void initState() {
    super.initState();
    _prevStatus = widget.agent.status;
    _chainScrollController.addListener(_updateChainMask);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isRunning(widget.agent) && !_chainCollapsed) {
        _scheduleChainScrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _chainScrollController.removeListener(_updateChainMask);
    _chainScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SingleAgentTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    final agent = widget.agent;
    final isDone = agent.status == DeepSearchRoundStatus.done;
    final isRunning = _isRunning(agent);
    final toolCount = countToolCalls(agent.contentBlocks);
    final classified = classifyBlocks(
      agent.contentBlocks,
      allowFallbackSummary: !isRunning,
    );
    final showTree = toolCount > 0 || classified.segments.isNotEmpty;

    if (isRunning && (_chainCollapsed || !_chainAutoScroll)) {
      setState(() {
        _chainCollapsed = false;
        _chainAutoScroll = true;
      });
    } else if (isDone && _prevStatus != DeepSearchRoundStatus.done) {
      setState(() {
        _chainCollapsed = showTree;
        _userExpanded = false;
        if (_chainCollapsed) {
          _chainMaskTop = false;
          _chainMaskBottom = false;
        }
      });
    }
    _prevStatus = agent.status;

    final signature = _segmentsSignature(classified.segments);
    if (signature != _lastSegmentsSignature) {
      _lastSegmentsSignature = signature;
      if (!_chainCollapsed && isRunning) {
        _scheduleChainScrollToBottom();
      }
    }
  }

  bool _isRunning(SubAgentInfo agent) =>
      agent.status != DeepSearchRoundStatus.done &&
      agent.status != DeepSearchRoundStatus.error;

  String _segmentsSignature(List<TreeSegment> segments) {
    return segments.map((segment) {
      if (segment is ThinkingTreeSegment) {
        return 'thinking:${segment.id}:${segment.blocks.map((b) => '${b.id}:${b.text.length}:${b.isStreaming ? 1 : 0}').join(',')}';
      }
      if (segment is ToolGroupTreeSegment) {
        return 'tool-group:${segment.id}:${segment.group.tools.map((t) => '${t.id}:${t.status.name}').join(',')}';
      }
      return segment.runtimeType.toString();
    }).join('|');
  }

  void _updateChainMask() {
    if (!_chainScrollController.hasClients) {
      if (_chainMaskTop || _chainMaskBottom) {
        setState(() {
          _chainMaskTop = false;
          _chainMaskBottom = false;
        });
      }
      return;
    }
    final pos = _chainScrollController.position;
    final nextTop = pos.pixels > 2;
    final nextBottom =
        pos.pixels + pos.viewportDimension < pos.maxScrollExtent - 2;
    if (nextTop != _chainMaskTop || nextBottom != _chainMaskBottom) {
      setState(() {
        _chainMaskTop = nextTop;
        _chainMaskBottom = nextBottom;
      });
    }
  }

  void _scrollChainToBottom() {
    if (_chainCollapsed || !_isRunning(widget.agent) || !_chainAutoScroll) {
      return;
    }
    if (!_chainScrollController.hasClients) return;
    _chainScrollController.jumpTo(_chainScrollController.position.maxScrollExtent);
    _updateChainMask();
  }

  void _scheduleChainScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollChainToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollChainToBottom();
      });
    });
  }

  void _cancelChainAutoScroll() {
    _chainAutoScroll = false;
  }

  void _handleChainScroll() {
    if (!_chainScrollController.hasClients) return;
    _updateChainMask();
    final pos = _chainScrollController.position;
    if (pos.pixels + pos.viewportDimension < pos.maxScrollExtent - 24) {
      _chainAutoScroll = false;
    }
  }

  Widget _buildCollapsibleSection({
    required bool visible,
    required Widget child,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: visible
          ? child
          : const SizedBox(width: double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final isDone = agent.status == DeepSearchRoundStatus.done;
    final isError = agent.status == DeepSearchRoundStatus.error;
    final isRunning = _isRunning(agent);
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
        ? TraceStrings.searchComplete
        : isSearching
            ? null
            : isRunning
                ? TraceStrings.searching
                : isError
                    ? TraceStrings.searchFailed
                    : TraceStrings.search;

    final showTree = toolCount > 0 || classified.segments.isNotEmpty;
    final hasIntro =
        classified.initialThinking.isNotEmpty || classified.opening != null;
    final showIntro = !_chainCollapsed && hasIntro;
    final showChainTree = showTree &&
        !_chainCollapsed &&
        (isRunning || classified.segments.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!showTree && showIntro) ...[
          if (classified.initialThinking.isNotEmpty)
            _ThinkingBubbleView(blocks: classified.initialThinking),
          if (classified.opening != null)
            Padding(
              padding: EdgeInsets.only(top: widget.compactTop ? 4 : 0),
              child: NarrationBlockView(
                block: classified.opening!,
                isFirstInRound: true,
              ),
            ),
        ],
        if (showTree) ...[
          _buildCollapsibleSection(
            visible: showIntro,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (classified.initialThinking.isNotEmpty)
                  _ThinkingBubbleView(blocks: classified.initialThinking),
                if (classified.opening != null)
                  Padding(
                    padding: EdgeInsets.only(top: widget.compactTop ? 4 : 0),
                    child: NarrationBlockView(
                      block: classified.opening!,
                      isFirstInRound: true,
                    ),
                  ),
              ],
            ),
          ),
          // Web: `flex items-center leading-7 ml-1 cursor-pointer` — no top margin.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                _chainCollapsed = !_chainCollapsed;
                if (_chainCollapsed) {
                  _chainMaskTop = false;
                  _chainMaskBottom = false;
                } else if (_chainAutoScroll && isRunning) {
                  _scheduleChainScrollToBottom();
                }
              }),
              borderRadius: BorderRadius.circular(8),
              hoverColor: const Color(0xFFFBFAF7),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SizedBox(
                  height: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: _SpiralSpinner(size: 16),
                        ),
                      if (headerText != null)
                        Text(
                          headerText,
                          style: TextStyle(
                            fontSize: 15,
                            height: 28 / 15,
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
                          minMs: 5000,
                          maxMs: 8000,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 28 / 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B6862),
                          ),
                        ),
                      if (isSearching) const _PulsingDots(),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          TraceStrings.chainSubtitle(
                            agent.candidatesFound,
                            toolCount,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 28 / 12,
                            color: Color(0xFF8A8880),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildCollapsibleSection(
            visible: showChainTree,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isRunning && !hasStarted)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 20),
                    child: Row(
                      children: [
                        _BounceSpinner(),
                        SizedBox(width: 6),
                        Text(
                          TraceStrings.initializing,
                          style: TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
                        ),
                      ],
                    ),
                  ),
                if (classified.segments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification &&
                                notification.dragDetails != null) {
                              _cancelChainAutoScroll();
                            }
                            if (notification is UserScrollNotification) {
                              _handleChainScroll();
                            }
                            return false;
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: SingleChildScrollView(
                              controller: _chainScrollController,
                              padding: const EdgeInsets.only(right: 4),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (isRunning)
                                    const Positioned(
                                      left: 0,
                                      top: 0,
                                      child: TreeTopTrunk(animated: true),
                                    ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children:
                                        classified.segments.asMap().entries.map((entry) {
                                      final segment = entry.value;
                                      final isLast =
                                          entry.key == classified.segments.length - 1;
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
                                          isActive: entry.key == lastToolGroupIdx &&
                                              isRunning,
                                          searchRunning: isRunning,
                                          userExpanded: _userExpanded,
                                          onUserExpand: () =>
                                              setState(() => _userExpanded = true),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_chainMaskTop)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 32,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFFAF9F6),
                                      Color(0x00FAF9F6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_chainMaskBottom)
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 32,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color(0xFFFAF9F6),
                                      Color(0x00FAF9F6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _sourceRowStats({
  required int toolCount,
  required int found,
  required double? durationS,
}) {
  final parts = <String>[];
  if (toolCount > 0) {
    parts.add(TraceStrings.toolUses(toolCount));
  }
  if (found > 0) {
    parts.add(TraceStrings.agentFound(found));
  }
  if (durationS != null) {
    parts.add('${durationS.round()}s');
  }
  return parts.join(' · ');
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
    final label = TraceStrings.sourceLabelForAgentName(agent.name);
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: TreeSolidLConnector(
            width: _indent - 2,
            height: treeL1BranchCenterNoPad,
            radius: 8,
          ),
        ),
        if (!widget.isLast)
          TreeVerticalTrunk(
            left: 0,
            top: treeL1BranchCenterNoPad - 8,
            bottom: 0,
            color: treeLineColor,
          ),
        Padding(
          padding: EdgeInsets.only(
            left: _indent,
            bottom: widget.isLast ? 0 : 8,
          ),
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
                          height: treeLeading7 / 14,
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
                      _sourceRowStats(
                        toolCount: toolBlocks.length,
                        found: agent.candidatesFound,
                        durationS: isDone ? agent.durationS : null,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A8880),
                      ),
                    ),
                  ],
                ),
              ),
              if (showInitializing)
                const _SubActivityLine(
                  text: TraceStrings.initializingEllipsis,
                  showSpinner: true,
                ),
              if (showActivity)
                _SubActivityLine(text: toolToGerund(latestTool.name)),
              if (_expanded)
                ...detailBlocks.map(
                  (block) => block is ToolCallPart
                      ? _ToolTreeNode(
                          block: block.block,
                          isLastChild: false,
                          isActiveParent: false,
                          toolRunning:
                              block.block.status == ToolCallStatus.running,
                        )
                      : Padding(
                          padding: const EdgeInsets.only(left: _indentL2, top: 4),
                          child: block is ReasoningPart
                              ? Text(
                                  block.block.text.length > 150
                                      ? block.block.text
                                          .substring(
                                            block.block.text.length - 150,
                                          )
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
        ),
      ],
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
    final showActivity = !showTools &&
        hasTools &&
        latestTool != null &&
        latestTool.status == ToolCallStatus.running;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: widget.isActive
              ? TreeMarchingAntsL(
                  width: _indent - 2,
                  height: treeL1BranchCenter,
                  radius: 8,
                )
              : TreeSolidLConnector(
                  width: _indent - 2,
                  height: treeL1BranchCenter,
                  radius: 8,
                  showLeftBorder: !widget.searchRunning,
                ),
        ),
        if (!widget.isLast)
          TreeVerticalTrunk(
            left: 0,
            top: 0,
            bottom: 0,
            color: treeLineColor,
            animated: widget.searchRunning,
          ),
        Padding(
          padding: const EdgeInsets.only(left: _indent, top: treeRowTopPad),
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
                          height: treeLeading7 / 14,
                          color: widget.isActive
                              ? const Color(0xFF2A2826)
                              : const Color(0xFF4A4843),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!showTools && hasTools)
                      Text(
                        TraceStrings.toolCountLabel(group.tools.length),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8880),
                        ),
                      ),
                  ],
                ),
              ),
              if (showInitializing)
                const _SubActivityLine(
                  text: TraceStrings.preparingToolsEllipsis,
                  showSpinner: true,
                ),
              if (showActivity)
                _SubActivityLine(text: toolToGerund(latestTool.name)),
              if (showTools && hasTools)
                ...group.tools.asMap().entries.map((entry) {
                  final bi = entry.key;
                  final block = entry.value;
                  final isLastChild = bi == group.tools.length - 1;
                  final toolRunning = block.status == ToolCallStatus.running;
                  return _ToolTreeNode(
                    block: block,
                    isLastChild: isLastChild,
                    isActiveParent: widget.isActive,
                    toolRunning: toolRunning,
                  );
                }),
            ],
          ),
        ),
      ],
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: TreeSolidLConnector(
            width: _indent - 2,
            height: treeL1BranchCenter,
            radius: 8,
            showLeftBorder: !searchRunning,
          ),
        ),
        if (!isLast)
          TreeVerticalTrunk(
            left: 0,
            top: 0,
            bottom: 0,
            color: treeLineColor,
            animated: searchRunning,
          ),
        Padding(
          padding: const EdgeInsets.only(left: _indent, top: treeRowTopPad),
          child: _ThinkingBubbleView(blocks: blocks),
        ),
      ],
    );
  }
}

const _streamingThinkingPreviewChars = 3000;

class _ThinkingBubbleView extends StatefulWidget {
  const _ThinkingBubbleView({required this.blocks});

  final List<ThinkingBlock> blocks;

  @override
  State<_ThinkingBubbleView> createState() => _ThinkingBubbleViewState();
}

class _ThinkingBubbleViewState extends State<_ThinkingBubbleView>
    with SingleTickerProviderStateMixin {
  var _expanded = false;
  var _hovering = false;
  late final AnimationController _shimmerController;

  static final _markdownStyle = MarkdownStyleSheet(
    p: const TextStyle(
      fontSize: 12,
      height: 1.625,
      color: Color(0xFF8A8880),
    ),
    strong: const TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFF9E9B93),
    ),
    listBullet: const TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
    blockSpacing: 4,
    listIndent: 16,
  );

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.blocks.isEmpty) return const SizedBox.shrink();
    final isStreaming = widget.blocks.any((b) => b.isStreaming);
    final totalText = widget.blocks.map((b) => b.text).join();
    final displayText = isStreaming &&
            totalText.length > _streamingThinkingPreviewChars
        ? totalText.substring(
            totalText.length - _streamingThinkingPreviewChars,
          )
        : totalText;
    final startedAt = widget.blocks.first.startedAt;
    final endedAt = widget.blocks.last.endedAt;
    final durationMs = !isStreaming && startedAt != 0
        ? ((endedAt ?? DateTime.now().millisecondsSinceEpoch) - startedAt)
        : null;
    final durationLabel = durationMs == null
        ? null
        : durationMs < 1000
            ? '${durationMs}ms'
            : '${(durationMs / 1000).toStringAsFixed(1)}s';
    final labelColor =
        _hovering ? const Color(0xFF6B6862) : const Color(0xFF9E9B93);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.chevron_right,
                    size: 12,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 6),
                if (isStreaming)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -1.5),
                        child: _HalfCircleSpinner(color: labelColor),
                      ),
                      const SizedBox(width: 6),
                      _ThinkingShimmerLabel(
                        controller: _shimmerController,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _RotatingText(
                              messages: thinkingMessages,
                              active: true,
                              minMs: 4000,
                              maxMs: 8000,
                              style: TextStyle(
                                fontSize: 12,
                                color: labelColor,
                              ),
                            ),
                            _PulsingDots(color: labelColor),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    durationLabel == null
                        ? TraceStrings.thought
                        : TraceStrings.thoughtForDuration(durationLabel),
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          clipBehavior: Clip.hardEdge,
          child: _expanded
              ? Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: 8),
                  child: SingleChildScrollView(
                    child: isStreaming
                        ? SelectableText(
                            displayText,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.625,
                              color: Color(0xFF8A8880),
                            ),
                          )
                        : MarkdownBody(
                            data: displayText,
                            selectable: true,
                            styleSheet: _markdownStyle,
                          ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ThinkingShimmerLabel extends StatelessWidget {
  const _ThinkingShimmerLabel({
    required this.controller,
    required this.child,
  });

  final AnimationController controller;
  final Widget child;

  static const _shimmerColors = <Color>[
    Color(0xFF9E9B93),
    Color(0xFFC6C3BD),
    Color(0xFF9E9B93),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + controller.value * 2, 0),
              end: Alignment(controller.value * 2, 0),
              colors: _shimmerColors,
              stops: const [0, 0.5, 1],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: child,
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
                  TraceStrings.submittedCandidates,
                  style: TextStyle(
                    fontSize: 12,
                    height: treeLeading6 / 12,
                    color: Color(0xFFA5A39E),
                  ),
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
                        height: treeLeading6 / 12,
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
  const _SubActivityLine({
    required this.text,
    this.showSpinner = false,
  });

  final String text;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final connectorWidth = _indentL2 - _l2LineLeft - 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _l2LineLeft,
          top: 0,
          child: TreeSolidLConnector(
            width: connectorWidth,
            height: treeL2ActivityBranchCenter,
            radius: 7,
            color: treeLineColorL2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _indentL2, top: 2),
          child: Row(
            children: [
              if (showSpinner) const _BounceSpinner(),
              if (showSpinner) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    height: treeLeading5 / 12,
                    color: Color(0xFF8A8880),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolTreeNode extends StatelessWidget {
  const _ToolTreeNode({
    required this.block,
    required this.isLastChild,
    required this.isActiveParent,
    required this.toolRunning,
  });

  final ToolCallBlock block;
  final bool isLastChild;
  final bool isActiveParent;
  final bool toolRunning;

  @override
  Widget build(BuildContext context) {
    final connectorWidth = _indentL2 - _l2LineLeft - 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _l2LineLeft,
          top: 0,
          child: toolRunning
              ? TreeMarchingAntsL(
                  width: connectorWidth,
                  height: treeL2BranchCenter,
                  radius: 7,
                  color: treeLineColorL2,
                )
              : TreeSolidLConnector(
                  width: connectorWidth,
                  height: treeL2BranchCenter,
                  radius: 7,
                  color: treeLineColorL2,
                  showLeftBorder: !isActiveParent,
                ),
        ),
        if (!isLastChild)
          TreeVerticalTrunk(
            left: _l2LineLeft,
            top: toolRunning ? 0 : treeL2BranchCenter - 7,
            bottom: 0,
            color: treeLineColorL2,
            animated: isActiveParent,
          ),
        Padding(
          padding: const EdgeInsets.only(left: _indentL2 + 2),
          child: _ToolNodeContent(block: block),
        ),
      ],
    );
  }
}

class _RotatingText extends StatefulWidget {
  const _RotatingText({
    required this.messages,
    required this.active,
    required this.style,
    this.minMs = 3000,
    this.maxMs = 6000,
  });

  final List<String> messages;
  final bool active;
  final TextStyle style;
  final int minMs;
  final int maxMs;

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
    final span = (widget.maxMs - widget.minMs).clamp(1, 1 << 30);
    final delayMs = widget.minMs + _random.nextInt(span);
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

class _PulsingDots extends StatefulWidget {
  const _PulsingDots({this.color = const Color(0xFF8A8880)});

  final Color color;

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOpacity(double phaseOffset) {
    final t = (_controller.value + phaseOffset) % 1.0;
    if (t < 0.5) return 0.25 + t * 1.5;
    return 1.75 - t * 1.5;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final phase in [0.0, 0.2 / 1.4, 0.4 / 1.4])
                Text(
                  '.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    color: widget.color.withValues(
                      alpha: _dotOpacity(phase).clamp(0.25, 1.0),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
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
  const _HalfCircleSpinner({this.color = const Color(0xFF9E9B93)});

  final Color color;

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
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        height: 1,
        color: widget.color,
      ),
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
