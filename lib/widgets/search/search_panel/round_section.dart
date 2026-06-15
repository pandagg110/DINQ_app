import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../agentic_search_logic.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/deep_search_results.dart';
import '../deep_search/deep_search_results_helpers.dart';
import '../deep_search/sub_agent_tracker.dart';
import '../citation/citation_results_view.dart';
import '../analysis/analysis_config.dart';
import '../analysis/analysis_results_view.dart';
import '../analysis/analysis_tool_phases.dart';
import '../advisor/advisors_results_view.dart';
import '../message_group/assistant_narration_view.dart';
import '../message_group/dinq_logo.dart';
import '../message_group/dinq_results_view.dart';
import '../message_group/thinking_bubble.dart';
import 'collapsible_bubble.dart';
import 'message_stream.dart';
import 'tool_search_progress.dart';

bool isInsufficientCredits(String message) {
  final lower = message.toLowerCase();
  return lower.contains('credit') &&
      (lower.contains('insufficient') || lower.contains('exhaust'));
}

String formatLogRecordTimestamp(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final local = d.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m';
}

DeepSearchRoundStatus _roundStatus(AgenticMessageGroup group) {
  if (group.roundStatus != DeepSearchRoundStatus.idle) {
    return group.roundStatus;
  }
  if (group.errorMessage != null && group.searchCompleted) {
    return DeepSearchRoundStatus.error;
  }
  if (group.loading && !group.searchCompleted) {
    return DeepSearchRoundStatus.searching;
  }
  if (group.searchCompleted) return DeepSearchRoundStatus.done;
  return DeepSearchRoundStatus.idle;
}

bool _hasReasoningBlock(
  AgenticMessageGroup group,
  bool Function(ReasoningBlock block) test,
) {
  for (final part in group.contentBlocks) {
    if (part is ReasoningPart && test(part.block)) return true;
  }
  for (final agent in group.subAgents.values) {
    for (final part in agent.contentBlocks) {
      if (part is ReasoningPart && test(part.block)) return true;
    }
  }
  return false;
}

/// 与 TSX SearchPanel.RoundSection 对齐。
class RoundSection extends StatefulWidget {
  const RoundSection({
    super.key,
    required this.group,
    required this.isLatest,
    required this.hideUserQueryBubble,
    required this.onCandidateClick,
    required this.copied,
    required this.onCopyMarkdown,
    this.onQuickReplySelect,
    this.onAdvisorShuffle,
    this.advisorShuffleLoading = false,
    this.selectedRowId,
  });

  final AgenticMessageGroup group;
  final bool isLatest;
  final bool hideUserQueryBubble;
  final ValueChanged<String>? onQuickReplySelect;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)
      onCandidateClick;
  final bool copied;
  final VoidCallback onCopyMarkdown;
  final VoidCallback? onAdvisorShuffle;
  final bool advisorShuffleLoading;
  final String? selectedRowId;

  @override
  State<RoundSection> createState() => _RoundSectionState();
}

class _RoundSectionState extends State<RoundSection> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final status = _roundStatus(group);
    final isSearching = status == DeepSearchRoundStatus.searching;
    final hasMessageParts = group.contentBlocks.isNotEmpty;
    final allowFallbackSummary = !isSearching;
    final toolType = group.toolType;
    final hasRows = group.candidates.isNotEmpty;
    final showResults = hasRows;
    final showMarkdownCopy = hasRows && status != DeepSearchRoundStatus.error;

    final hasPendingConfirmBlock = _hasReasoningBlock(
      group,
      (b) => b.text.startsWith('[confirm]') && !group.quickRepliesUsed,
    );

    final showQuickReplies = widget.isLatest &&
        widget.onQuickReplySelect != null &&
        !group.quickRepliesUsed &&
        !group.assistantStreaming &&
        group.candidates.isEmpty;

    final attachment = group.pdfAttachment;
    final displayQuery = group.displayQuery ?? group.userQuery;
    final isDinqSearch = group.searchType == 'dinq';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hideUserQueryBubble && group.recordCreatedAt != null)
          Text(
            formatLogRecordTimestamp(group.recordCreatedAt!),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9B93),
            ),
          ),

        if (!widget.hideUserQueryBubble)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: CollapsibleBubble(
              text: displayQuery,
              attachment: attachment,
            ),
          ),

        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (group.subAgents.isNotEmpty)
                SubAgentTracker(
                  subAgents: group.subAgents,
                  compactTop: widget.hideUserQueryBubble,
                ),

              if (hasMessageParts)
                MessagePartListProcess(
                  blocks: group.contentBlocks,
                  allowFallbackSummary: allowFallbackSummary,
                  showQuickReplies: showQuickReplies,
                  quickRepliesUsed: group.quickRepliesUsed,
                  hasCandidates: hasRows,
                  onQuickReplySelect: widget.onQuickReplySelect,
                )
              else ...[
                if (isDinqSearch)
                  DinqResultsView(
                    results: group.dinqResults ?? [],
                    loading: group.loading,
                  ),
                if (!isDinqSearch &&
                    !group.isDeepSearch &&
                    group.thinkingSteps.isNotEmpty)
                  ThinkingBubble(
                    steps: group.thinkingSteps,
                    expanded: group.thinkingExpanded,
                    loading: group.loading,
                    onToggle: () {},
                  ),
                if (!isDinqSearch &&
                    group.assistantText.trim().isNotEmpty &&
                    group.subAgents.isEmpty)
                  AssistantNarrationView(
                    text: group.assistantText,
                    blockId: 'group-${group.id}',
                    isStreaming: group.assistantStreaming,
                    showQuickReplies: showQuickReplies,
                    quickRepliesUsed: group.quickRepliesUsed,
                    hasCandidates: hasRows,
                    onQuickReplySelect: widget.onQuickReplySelect,
                  ),
              ],
            ],
          ),
        ),

        if (group.errorMessage != null && status == DeepSearchRoundStatus.error)
          _RoundErrorBar(
            message: group.errorMessage!,
            isCreditsError: isInsufficientCredits(group.errorMessage!),
            showToolActions: toolType != null,
            onUpgrade: () => context.push('/pricing'),
            onRetry: () => context.go('/search'),
          ),

        if (toolType == 'who-cites-me' && group.toolResult != null)
          _CitationToolSection(
            group: group,
            onCandidateClick: widget.onCandidateClick,
          ),

        if (toolType == 'find-advisor' &&
            (group.toolResult != null || (group.advisorResults?.isNotEmpty ?? false)))
          _AdvisorToolSection(
            group: group,
            onCandidateClick: widget.onCandidateClick,
            onShuffle: widget.onAdvisorShuffle,
            shuffleLoading: widget.advisorShuffleLoading,
          ),

        if (toolType == 'analysis' && group.toolResult != null)
          _AnalysisToolSection(
            group: group,
            onCandidateClick: widget.onCandidateClick,
          ),

        if (toolType == null && showResults)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: DeepSearchResults(
              candidates: group.candidates,
              isSearching: isSearching,
              isInterrupted: status == DeepSearchRoundStatus.interrupted,
              selectedRowId: widget.selectedRowId,
              onRowClick: (row) {
                final idx = group.candidates.indexWhere(
                  (c) =>
                      c['row_id']?.toString() == row['row_id']?.toString() ||
                      c['name'] == row['name'],
                );
                widget.onCandidateClick(
                  candidateRowToTabCandidate(row),
                  idx >= 0 ? idx : 0,
                  group.id,
                );
              },
            ),
          ),

        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.subAgents.isNotEmpty)
                SingleAgentSummary(subAgents: group.subAgents),
              if (hasMessageParts)
                MessagePartListSummary(
                  blocks: group.contentBlocks,
                  allowFallbackSummary: allowFallbackSummary,
                ),
              if (showMarkdownCopy)
                RoundMarkdownCopyButton(
                  alwaysVisible: widget.isLatest || _isHovered,
                  copied: widget.copied,
                  onCopy: widget.onCopyMarkdown,
                ),
            ],
          ),
        ),

        if (widget.isLatest &&
            toolType == null &&
            !hasPendingConfirmBlock &&
            !widget.hideUserQueryBubble)
          Transform.translate(
            offset: Offset(0, showMarkdownCopy ? 4 : -8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: DinqLogoButton(
                isLoading: isSearching,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdvisorToolSection extends StatelessWidget {
  const _AdvisorToolSection({
    required this.group,
    required this.onCandidateClick,
    this.onShuffle,
    this.shuffleLoading = false,
  });

  final AgenticMessageGroup group;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)
      onCandidateClick;
  final VoidCallback? onShuffle;
  final bool shuffleLoading;

  @override
  Widget build(BuildContext context) {
    final result = group.toolResult;
    final advisors = result?['advisors'] is List
        ? (result!['advisors'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : (group.advisorResults ?? []);
    final rounds = result?['rounds'] is List ? result!['rounds'] as List : null;
    final isSearching = _roundStatus(group) == DeepSearchRoundStatus.searching;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdvisorsResultsView(
        advisors: advisors,
        rounds: rounds,
        isSearching: isSearching,
        onShuffle: onShuffle,
        shuffleLoading: shuffleLoading,
        onEnrich: (row) => onCandidateClick(row, 0, group.id),
      ),
    );
  }
}

class RoundMarkdownCopyButton extends StatelessWidget {
  const RoundMarkdownCopyButton({
    super.key,
    required this.alwaysVisible,
    required this.copied,
    required this.onCopy,
  });

  final bool alwaysVisible;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    // 与 TSX RoundMarkdownCopyButton：左对齐 flex h-6 items-center，无 Spacer
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onCopy,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: alwaysVisible || copied ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  copied ? Icons.check : Icons.content_copy,
                  size: 14,
                  color: const Color(0xFF9E9B93),
                ),
              ),
            ),
          ),
          if (copied)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3D3B37),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Copied',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundErrorBar extends StatelessWidget {
  const _RoundErrorBar({
    required this.message,
    required this.isCreditsError,
    required this.showToolActions,
    required this.onUpgrade,
    required this.onRetry,
  });

  final String message;
  final bool isCreditsError;
  final bool showToolActions;
  final VoidCallback onUpgrade;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFECE8E0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFF9E9B93)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A8880)),
            ),
          ),
          if (!showToolActions && isCreditsError)
            OutlinedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.bolt, size: 14),
              label: const Text('Upgrade'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2A2826),
                side: const BorderSide(color: Color(0xFFE0DDD7)),
                backgroundColor: const Color(0xFFF5F4F0),
                visualDensity: VisualDensity.compact,
              ),
            )
          else if (!showToolActions)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B6862),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _CitationToolSection extends StatelessWidget {
  const _CitationToolSection({
    required this.group,
    required this.onCandidateClick,
  });

  final AgenticMessageGroup group;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)
      onCandidateClick;

  @override
  Widget build(BuildContext context) {
    final result = group.toolResult!;
    final phase = result['phase']?.toString();
    final data = result['data'];
    final isSearching = _roundStatus(group) == DeepSearchRoundStatus.searching;
    final isStopped = group.roundStatus == DeepSearchRoundStatus.interrupted;
    final citers = data is Map && data['citers'] is List
        ? (data['citers'] as List)
        : <dynamic>[];
    final citationCount = citers.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolSearchProgress(
            phases: buildCitationPhases(phase, !isSearching),
            isFinished: !isSearching || isStopped,
            finishedLabel: isStopped
                ? (group.errorMessage ?? 'Stopped')
                : 'Found $citationCount citing ${citationCount == 1 ? 'author' : 'authors'}',
          ),
          if (data is Map)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CitationResultsView(
                data: Map<String, dynamic>.from(data),
                onEnrich: (row) => onCandidateClick(row, 0, group.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisToolSection extends StatelessWidget {
  const _AnalysisToolSection({
    required this.group,
    required this.onCandidateClick,
  });

  final AgenticMessageGroup group;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)
      onCandidateClick;

  @override
  Widget build(BuildContext context) {
    final result = group.toolResult!;
    final cards = result['cards'];
    final platform = result['platform']?.toString() ?? 'scholar';
    final platformOrder = AnalysisPlatformConfig.cardOrder(platform);
    final cardCount = cards is Map
        ? platformOrder
            .where(
              (key) =>
                  cards[key] is Map &&
                  (cards[key] as Map)['status'] == 'completed',
            )
            .length
        : 0;
    final isDone = _roundStatus(group) == DeepSearchRoundStatus.done ||
        group.roundStatus == DeepSearchRoundStatus.interrupted;
    final isStopped = group.roundStatus == DeepSearchRoundStatus.interrupted;
    final rounds = result['rounds'] is List ? result['rounds'] as List : const [];
    final analysisPhases = buildAnalysisPhases(
      rounds: rounds,
      isFinished: isDone,
      cardCount: cardCount,
      cards: cards is Map ? Map<String, dynamic>.from(cards as Map) : null,
      platform: platform,
    );
    final query = result['query']?.toString() ?? group.userQuery;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolSearchProgress(
            phases: analysisPhases,
            isFinished: isDone,
            finishedLabel: isStopped
                ? (group.errorMessage ?? 'Stopped')
                : cardCount > 0
                    ? 'Analysis complete · $cardCount ${cardCount == 1 ? 'card' : 'cards'}'
                    : 'No results found',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
          ),
          AnalysisResultsView(
            platform: platform,
            cards: Map<String, dynamic>.from(
              cards is Map ? cards as Map : const {},
            ),
            query: query,
            loading: !isDone,
            onEnrich: () => onCandidateClick(
              _analysisToRow(query, platform),
              0,
              group.id,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _analysisToRow(String query, String platform) {
    var profileUrl = '';
    if (platform == 'scholar' && query.contains('scholar.google.com')) {
      profileUrl = query;
    } else if (platform == 'github') {
      profileUrl = query.startsWith('http') ? query : 'https://github.com/$query';
    } else if (platform == 'linkedin' && query.contains('linkedin.com')) {
      profileUrl = query;
    }
    return {
      'row_id': 'analysis-$platform-$query',
      'name': query,
      'title': '',
      'company': '',
      'evidence': '$platform analysis',
      'profile_url': profileUrl,
      'source': platform,
      'confidence': 0,
    };
  }
}
