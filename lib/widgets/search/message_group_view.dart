import 'package:flutter/material.dart';
import 'deep_search/deep_search_results.dart';
import 'deep_search/deep_search_results_helpers.dart';
import 'deep_search/sub_agent_tracker.dart';
import 'message_group/action_bar.dart';
import 'message_group/advisors_list.dart';
import 'message_group/assistant_narration_view.dart';
import 'message_group/attachment_file_chip.dart';
import 'message_group/deep_search_progress_header.dart';
import 'message_group/dinq_logo.dart';
import 'message_group/dinq_results_view.dart';
import 'message_group/message_group_types.dart';
import 'message_group/pdf_preview_modal.dart';
import 'message_group/thinking_bubble.dart';

// 对外统一导出类型，与 TSX 的 types 对应
export 'message_group/message_group_types.dart';

/// 与 TSX RoundSection / CollapsibleBubble 同步
class MessageGroupView extends StatefulWidget {
  const MessageGroupView({
    super.key,
    required this.group,
    this.onToggleThinking,
    this.onCandidateClick,
    this.onQuickReplySelect,
    this.isLatest = false,
  });

  final MessageGroupData group;
  final VoidCallback? onToggleThinking;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)?
      onCandidateClick;
  final ValueChanged<String>? onQuickReplySelect;
  final bool isLatest;

  @override
  State<MessageGroupView> createState() => _MessageGroupViewState();
}

class _MessageGroupViewState extends State<MessageGroupView>
    with SingleTickerProviderStateMixin {
  String? _feedback;
  bool _showPdfModal = false;
  bool _hovering = false;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isDinqSearch = group.searchType == 'dinq';
    final isAdvisorSearch = group.searchType == 'advisor';
    final hasCandidates = group.candidates.isNotEmpty;
    final hasDinqResults = (group.dinqResults?.length ?? 0) > 0;
    final hasAdvisorResults = (group.advisorResults?.length ?? 0) > 0;
    final hasPdfAttachment = group.pdfAttachment != null;
    final rawAssistantText = group.assistantText?.trim() ?? '';
    final hasAssistantText =
        rawAssistantText.isNotEmpty || group.assistantStreaming;
    final showQuickReplies = widget.isLatest &&
        !group.quickRepliesUsed &&
        !group.assistantStreaming &&
        group.candidates.isEmpty;
    // 与 Dinq-client 一致：Search complete 标题仅在搜索进行中显示，完成后隐藏工具树/标题行
    final hasSubAgents = group.subAgents.isNotEmpty;
    final showDeepSearchHeader = group.isDeepSearch &&
        group.loading &&
        !group.searchCompleted &&
        group.deepSearchToolCount > 0 &&
        !hasSubAgents;
    final showLegacyAssistantText =
        !isDinqSearch && hasAssistantText && !hasSubAgents;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasPdfAttachment) ...[
                    AttachmentFileChip(
                      name: group.pdfAttachment!['name'] as String? ?? 'PDF',
                      onTap: () => setState(() => _showPdfModal = true),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (group.userQuery.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0EFE9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        group.userQuery,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          height: 1.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_showPdfModal && hasPdfAttachment)
            PdfPreviewModal(
              url: group.pdfAttachment!['url'] as String? ?? '',
              name: group.pdfAttachment!['name'] as String? ?? 'PDF',
              onClose: () => setState(() => _showPdfModal = false),
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDinqSearch)
                  DinqResultsView(
                    results: group.dinqResults ?? [],
                    loading: group.loading,
                  ),

                if (showLegacyAssistantText)
                  AssistantNarrationView(
                    text: rawAssistantText,
                    blockId: 'group-${group.id}',
                    isStreaming: group.assistantStreaming,
                    showQuickReplies: showQuickReplies,
                    quickRepliesUsed: group.quickRepliesUsed,
                    hasCandidates: hasCandidates,
                    onQuickReplySelect:
                        showQuickReplies ? widget.onQuickReplySelect : null,
                  ),

                if (hasSubAgents)
                  SubAgentTracker(
                    subAgents: group.subAgents,
                  ),

                if (showDeepSearchHeader)
                  DeepSearchProgressHeader(
                    isLoading: group.loading,
                    isDone: group.searchCompleted || hasCandidates,
                    toolCount: group.deepSearchToolCount,
                    foundCount: group.candidates.length,
                    durationMs: group.deepSearchDurationMs,
                  ),

                if (!isDinqSearch &&
                    !group.isDeepSearch &&
                    !hasAssistantText &&
                    group.thinkingSteps.isNotEmpty)
                  ThinkingBubble(
                    steps: group.thinkingSteps,
                    expanded: group.thinkingExpanded,
                    loading: group.loading,
                    onToggle: widget.onToggleThinking ?? () {},
                  ),

                if (group.isDeepSearch && hasCandidates)
                  Padding(
                    padding: EdgeInsets.only(top: hasSubAgents ? 24 : 0),
                    child: DeepSearchResults(
                      candidates: group.candidates,
                      isSearching: group.loading && !group.searchCompleted,
                      onRowClick: widget.onCandidateClick == null
                          ? null
                          : (row) {
                              final idx = group.candidates.indexWhere(
                                (c) =>
                                    c['row_id']?.toString() ==
                                        row['row_id']?.toString() ||
                                    c['name'] == row['name'],
                              );
                              widget.onCandidateClick!(
                                candidateRowToTabCandidate(row),
                                idx >= 0 ? idx : 0,
                                group.id,
                              );
                            },
                    ),
                  ),

                if (hasSubAgents && hasCandidates)
                  SingleAgentSummary(subAgents: group.subAgents),

                if (isAdvisorSearch && hasAdvisorResults)
                  AdvisorsList(advisors: group.advisorResults!),

                if (!isDinqSearch &&
                    group.loading &&
                    !hasAssistantText &&
                    !group.isDeepSearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: BreathingLogo(
                      size: 24,
                      animation: _breathingController,
                    ),
                  ),

                if (!group.loading &&
                    (hasCandidates || hasDinqResults || hasAdvisorResults)) ...[
                  if (widget.isLatest)
                    MessageGroupActionBar(
                      isLatest: true,
                      feedback: _feedback,
                      onFeedbackUp: () => setState(
                          () => _feedback = _feedback == 'up' ? null : 'up'),
                      onFeedbackDown: () => setState(() =>
                          _feedback = _feedback == 'down' ? null : 'down'),
                    )
                  else
                    AnimatedOpacity(
                      opacity: _hovering ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: MessageGroupActionBar(
                        isLatest: false,
                        feedback: _feedback,
                        onFeedbackUp: () => setState(
                            () => _feedback = _feedback == 'up' ? null : 'up'),
                        onFeedbackDown: () => setState(() =>
                            _feedback = _feedback == 'down' ? null : 'down'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
