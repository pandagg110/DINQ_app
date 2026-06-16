import 'package:flutter/material.dart';

import '../deep_search/deep_search_models.dart';
import '../deep_search/sub_agent_helpers.dart';
import 'phase_timeline.dart';
import 'tool_card.dart';

/// 与 TSX MessagePartListProcess 对齐。
class MessagePartListProcess extends StatelessWidget {
  const MessagePartListProcess({
    super.key,
    required this.blocks,
    required this.allowFallbackSummary,
  });

  final List<MessagePart> blocks;
  final bool allowFallbackSummary;

  @override
  Widget build(BuildContext context) {
    final processBlocks = splitRoundBlocks(
      blocks,
      allowFallbackSummary: allowFallbackSummary,
    ).processBlocks;

    final grouped = groupBlocksIntoPhases(processBlocks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grouped.firstNarration != null)
          NarrationBlockView(
            block: grouped.firstNarration!,
            isFirstInRound: true,
          ),
        for (var i = 0; i < grouped.phases.length; i++)
          PhaseSection(
            phase: grouped.phases[i],
            index: i,
            totalPhases: grouped.phases.length,
            isLast: i == grouped.phases.length - 1,
          ),
        for (final block in grouped.tailBlocks)
          _TailBlock(block: block),
      ],
    );
  }
}

/// 与 TSX MessagePartListSummary 对齐。
class MessagePartListSummary extends StatelessWidget {
  const MessagePartListSummary({
    super.key,
    required this.blocks,
    required this.allowFallbackSummary,
  });

  final List<MessagePart> blocks;
  final bool allowFallbackSummary;

  @override
  Widget build(BuildContext context) {
    final summaryBlock = splitRoundBlocks(
      blocks,
      allowFallbackSummary: allowFallbackSummary,
    ).summaryBlock;
    if (summaryBlock == null) return const SizedBox.shrink();

    return NarrationBlockView(
      block: summaryBlock,
      isSummary: true,
    );
  }
}

class _TailBlock extends StatelessWidget {
  const _TailBlock({required this.block});

  final MessagePart block;

  @override
  Widget build(BuildContext context) {
    if (block is ReasoningPart) {
      return NarrationBlockView(block: (block as ReasoningPart).block);
    }
    if (block is ToolCallPart) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ToolCard(block: (block as ToolCallPart).block),
      );
    }
    if (block is StatusPart) {
      return StatusChip(block: (block as StatusPart).block);
    }
    return const SizedBox.shrink();
  }
}

SplitRoundBlocksResult splitRoundBlocks(
  List<MessagePart> blocks, {
  required bool allowFallbackSummary,
}) {
  if (blocks.isEmpty) {
    return const SplitRoundBlocksResult(processBlocks: []);
  }

  final markedSummaryIdx = blocks.indexWhere(_isMarkedSummaryBlock);
  if (markedSummaryIdx >= 0) {
    final summaryPart = blocks[markedSummaryIdx] as ReasoningPart;
    return SplitRoundBlocksResult(
      processBlocks: [
        for (var i = 0; i < blocks.length; i++)
          if (i != markedSummaryIdx) blocks[i],
      ],
      summaryBlock: _cleanSummaryBlock(summaryPart),
    );
  }

  final last = blocks.last;
  if (allowFallbackSummary && _isSummaryBlock(blocks, last)) {
    return SplitRoundBlocksResult(
      processBlocks: blocks.sublist(0, blocks.length - 1),
      summaryBlock: _cleanSummaryBlock(last as ReasoningPart),
    );
  }

  return SplitRoundBlocksResult(processBlocks: blocks);
}

String getMessagePartSummaryText(
  List<MessagePart> blocks, {
  required bool allowFallbackSummary,
}) {
  final result = splitRoundBlocks(
    blocks,
    allowFallbackSummary: allowFallbackSummary,
  );
  return result.summaryBlock?.text.trim() ?? '';
}

/// 与 TSX MessageStream.splitRoundBlocks 对齐。
class SplitRoundBlocksResult {
  const SplitRoundBlocksResult({
    required this.processBlocks,
    this.summaryBlock,
  });

  final List<MessagePart> processBlocks;
  final ReasoningBlock? summaryBlock;
}

bool _isMarkedSummaryBlock(MessagePart part) {
  if (part is! ReasoningPart) return false;
  return hasSummaryPrefix(part.block.text) ||
      isSummaryPrefixPending(part.block.text);
}

ReasoningBlock _cleanSummaryBlock(ReasoningPart part) =>
    part.block.copyWith(text: stripSummaryPrefix(part.block.text));

bool _isSummaryBlock(List<MessagePart> blocks, MessagePart last) {
  if (last is! ReasoningPart) return false;
  final beforeLast = blocks.sublist(0, blocks.length - 1);
  final hasToolBeforeLast = beforeLast.any((b) => b is ToolCallPart);
  return hasToolBeforeLast && !last.block.isStreaming;
}
