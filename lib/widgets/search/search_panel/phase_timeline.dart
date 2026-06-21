import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../utils/parse_quick_replies.dart';
import '../message_group/quick_replies_widget.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/sub_agent_helpers.dart';
import 'confirm_block_view.dart';
import 'search_interaction_scope.dart';
import 'tool_card.dart';

/// 与 TSX PhaseTimeline.groupBlocksIntoPhases 对齐。
class GroupedPhasesResult {
  GroupedPhasesResult({
    this.firstNarration,
    this.phases = const [],
    this.tailBlocks = const [],
  });

  final ReasoningBlock? firstNarration;
  final List<PhaseData> phases;
  final List<MessagePart> tailBlocks;
}

class PhaseData {
  PhaseData({this.narration, List<MessagePart>? blocks})
      : blocks = blocks ?? <MessagePart>[];

  ReasoningBlock? narration;
  final List<MessagePart> blocks;
}

GroupedPhasesResult groupBlocksIntoPhases(List<MessagePart> blocks) {
  ReasoningBlock? firstNarration;
  final phases = <PhaseData>[];
  final tailBlocks = <MessagePart>[];

  if (blocks.isEmpty) {
    return GroupedPhasesResult(
      firstNarration: firstNarration,
      phases: phases,
      tailBlocks: tailBlocks,
    );
  }

  final firstReasoningIdx = blocks.indexWhere((b) => b is ReasoningPart);
  final firstToolIdx = blocks.indexWhere((b) => b is ToolCallPart);
  final hasFirstNarration =
      firstReasoningIdx >= 0 &&
      (firstToolIdx == -1 || firstReasoningIdx < firstToolIdx);

  var lastToolIdx = -1;
  var lastReasoningIdx = -1;
  for (var i = 0; i < blocks.length; i++) {
    if (blocks[i] is ToolCallPart) lastToolIdx = i;
    if (blocks[i] is ReasoningPart) lastReasoningIdx = i;
  }
  final hasSummary =
      lastReasoningIdx >= 0 &&
      lastToolIdx >= 0 &&
      lastReasoningIdx > lastToolIdx;

  PhaseData? currentPhase;
  var startIdx = 0;

  if (hasFirstNarration) {
    firstNarration = (blocks[firstReasoningIdx] as ReasoningPart).block;
    startIdx = firstReasoningIdx + 1;
  }

  for (var i = startIdx; i < blocks.length; i++) {
    final block = blocks[i];
    if (hasSummary &&
        i == lastReasoningIdx &&
        block is ReasoningPart) {
      if (currentPhase != null) phases.add(currentPhase);
      continue;
    }

    if (block is ReasoningPart) {
      if (block.block.isStreaming) {
        final hasMoreNonReasoning = blocks
            .sublist(i + 1)
            .any((b) => b is! ReasoningPart);
        if (!hasMoreNonReasoning) {
          if (currentPhase != null) phases.add(currentPhase);
          tailBlocks.addAll(blocks.sublist(i));
          return GroupedPhasesResult(
            firstNarration: firstNarration,
            phases: phases,
            tailBlocks: tailBlocks,
          );
        }
      }
      if (currentPhase != null) phases.add(currentPhase);
      currentPhase = PhaseData(narration: block.block);
    } else {
      currentPhase ??= PhaseData();
      currentPhase.blocks.add(block);
    }
  }

  if (currentPhase != null) phases.add(currentPhase);
  return GroupedPhasesResult(
    firstNarration: firstNarration,
    phases: phases,
    tailBlocks: tailBlocks,
  );
}

enum _PhaseStatus { active, completed, pending }

_PhaseStatus _derivePhaseStatus(PhaseData phase, bool isLastPhase) {
  final hasRunningTool = phase.blocks.any(
    (b) =>
        b is ToolCallPart && b.block.status == ToolCallStatus.running,
  );
  if (hasRunningTool || (phase.narration?.isStreaming ?? false)) {
    return _PhaseStatus.active;
  }
  if (isLastPhase) {
    final hasCompletedTool = phase.blocks.any(
      (b) =>
          b is ToolCallPart && b.block.status == ToolCallStatus.done,
    );
    return hasCompletedTool ? _PhaseStatus.completed : _PhaseStatus.active;
  }
  return _PhaseStatus.completed;
}

const _toolCategoryLabels = <String, String>{
  'firecrawl_search': 'Web Search',
  'brave_web_search': 'Web Search',
  'search_web': 'Web Search',
  'perplexity_search': 'AI Search',
  'firecrawl_scrape': 'Web Scrape',
  'search_ai_lab_talent': 'Academic Search',
  'search_hf_users': 'Profile Search',
  'search_github_talent': 'GitHub Search',
  'submit_candidates': 'Submit Candidates',
  'context_compaction': 'Context Compaction',
};

String _derivePhaseName(PhaseData phase) {
  final toolNames = phase.blocks
      .whereType<ToolCallPart>()
      .map((b) => b.block.name)
      .toList();
  if (toolNames.isNotEmpty) {
    final labels = toolNames.map((name) {
      for (final entry in _toolCategoryLabels.entries) {
        if (name.contains(entry.key)) return entry.value;
      }
      return 'Tool';
    }).toSet().toList();
    if (labels.length == 1) return labels.first;
    return labels.take(2).join(' + ');
  }
  return 'Processing';
}

/// 与 TSX PhaseSection 对齐（简化 UI）。
class PhaseSection extends StatefulWidget {
  const PhaseSection({
    super.key,
    required this.phase,
    required this.index,
    required this.totalPhases,
    required this.isLast,
  });

  final PhaseData phase;
  final int index;
  final int totalPhases;
  final bool isLast;

  @override
  State<PhaseSection> createState() => _PhaseSectionState();
}

class _PhaseSectionState extends State<PhaseSection> {
  bool _open = true;

  @override
  void didUpdateWidget(covariant PhaseSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final status = _derivePhaseStatus(widget.phase, widget.isLast);
    if (status == _PhaseStatus.completed && !widget.isLast) {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final status = _derivePhaseStatus(phase, widget.isLast);
    final toolCount = phase.blocks.whereType<ToolCallPart>().length;
    final phaseName = _derivePhaseName(phase);
    final showPhaseLabel = widget.totalPhases > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phase.narration != null)
          NarrationBlockView(block: phase.narration!),
        if (toolCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showPhaseLabel)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 12),
                    child: _PhaseStatusIcon(status: status),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _open = !_open),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (showPhaseLabel)
                                        Text(
                                          '${widget.index + 1}/${widget.totalPhases} ',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          phaseName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$toolCount tools',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _open
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_open)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: [
                                for (final block in phase.blocks)
                                  if (block is ToolCallPart)
                                    ToolCard(block: block.block)
                                  else if (block is StatusPart)
                                    StatusChip(block: block.block)
                                  else if (block is ReasoningPart)
                                    NarrationBlockView(block: block.block),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhaseStatusIcon extends StatelessWidget {
  const _PhaseStatusIcon({required this.status});

  final _PhaseStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _PhaseStatus.completed:
        return Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF5F9670),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        );
      case _PhaseStatus.active:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF5F9670),
          ),
        );
      case _PhaseStatus.pending:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
          ),
        );
    }
  }
}

/// 与 TSX `PhaseTimeline.NarrationBlockView` 严格对齐。
class NarrationBlockView extends StatelessWidget {
  const NarrationBlockView({
    super.key,
    required this.block,
    this.isSummary = false,
    this.isFirstInRound = false,
  });

  final ReasoningBlock block;
  final bool isSummary;
  final bool isFirstInRound;

  static const _confirmPrefix = '[confirm]';

  static MarkdownStyleSheet get _markdownStyle => MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF4A4845),
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A3835),
        ),
        h1: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2A2826),
        ),
        h2: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2A2826),
        ),
        h3: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A3835),
        ),
        blockquote: const TextStyle(
          color: Color(0xFF8A8880),
          fontStyle: FontStyle.normal,
        ),
        code: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4A4845),
          backgroundColor: Color(0xFFF5F4EF),
        ),
        listBullet: const TextStyle(color: Color(0xFFA5A39E)),
      );

  @override
  Widget build(BuildContext context) {
    final isConfirmPending = _confirmPrefix.startsWith(block.text) &&
        block.text.length < _confirmPrefix.length;
    final isSummaryPending = isSummaryPrefixPending(block.text);

    if (isConfirmPending || isSummaryPending) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: _TypingDots(),
      );
    }

    final envelope = parseEnvelope(block.text);
    final type = envelope.type;
    final cleanText = envelope.cleanText;
    final options = envelope.options;
    final hasContent = cleanText.isNotEmpty || options.isNotEmpty;

    if (!hasContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: _TypingDots(),
      );
    }

    if (type == 'confirm') {
      return ConfirmBlockView(
        block: block,
        onStartSearch: (query, displayQuery) {
          final scope = SearchInteractionScope.maybeOf(context);
          scope?.onConfirmStart?.call(query, displayQuery, block.id);
        },
      );
    }

    final scope = SearchInteractionScope.maybeOf(context);
    final onSelect = scope?.onQuickReplySelect;

    return Padding(
      padding: EdgeInsets.only(top: isFirstInRound ? 0 : 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cleanText.isNotEmpty)
            MarkdownBody(
              data: cleanText,
              selectable: true,
              styleSheet: _markdownStyle,
            ),
          if (options.isNotEmpty)
            QuickRepliesWidget(
              blockId: block.id,
              options: options,
              onSelect: onSelect != null
                  ? (option) => onSelect(option, block.id)
                  : (_) {},
            ),
        ],
      ),
    );
  }
}

/// 与 TSX StatusChip 对齐。
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.block});

  final StatusBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        block.message,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = (_controller.value + i * 0.2) % 1.0;
            final opacity = 0.3 + (t < 0.5 ? t : 1 - t) * 1.4;
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Color(0xFFD1D5DB).withValues(alpha: opacity.clamp(0.3, 1)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
