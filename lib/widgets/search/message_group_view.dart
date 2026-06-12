import 'package:flutter/material.dart';
import 'message_group/action_bar.dart';
import 'message_group/advisors_list.dart';
import 'message_group/dinq_logo.dart';
import 'message_group/dinq_results_view.dart';
import 'message_group/message_group_types.dart';
import 'message_group/pdf_preview_modal.dart';
import 'message_group/pdf_thumbnail.dart';
import 'message_group/scholars_list.dart';
import 'message_group/thinking_bubble.dart';

// 对外统一导出类型，与 TSX 的 types 对应
export 'message_group/message_group_types.dart';

/// 与 TSX MessageGroupView 同步：用户问题 + PDF（可选）+ AI 回复（Dinq/Thinking/Scholars/Advisors + 加载态 + 操作栏）
class MessageGroupView extends StatefulWidget {
  const MessageGroupView({
    super.key,
    required this.group,
    this.onToggleThinking,
    this.onCandidateClick,
    this.isLatest = false,
  });

  final MessageGroupData group;
  final VoidCallback? onToggleThinking;
  /// 与 TSX 一致：(candidate, index, groupId)
  final void Function(Map<String, dynamic> candidate, int index, int groupId)? onCandidateClick;
  final bool isLatest;

  @override
  State<MessageGroupView> createState() => _MessageGroupViewState();
}

class _MessageGroupViewState extends State<MessageGroupView>
    with SingleTickerProviderStateMixin {
  String? _feedback; // 'up' | 'down'
  bool _showPdfModal = false;
  bool _hovering = false; // 与 TSX group-hover/message:opacity-100 一致
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // 用户问题 - 靠右对齐（与 TSX flex items-end gap-3）
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasPdfAttachment) ...[
                PdfThumbnail(
                  name: group.pdfAttachment!['name'] as String? ?? 'PDF',
                  onTap: () => setState(() => _showPdfModal = true),
                ),
                const SizedBox(height: 12),
              ],
              // 文字消息：与 TSX bg-gray-50 rounded-2xl rounded-br-sm max-w-[85%]
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  group.userQuery,
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // PDF Modal（与 TSX PdfPreviewModal）
        if (_showPdfModal && hasPdfAttachment)
          PdfPreviewModal(
            url: group.pdfAttachment!['url'] as String? ?? '',
            name: group.pdfAttachment!['name'] as String? ?? 'PDF',
            onClose: () => setState(() => _showPdfModal = false),
          ),

        // AI 回复区域（与 TSX space-y-3 pl-0）
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

              if (!isDinqSearch && group.thinkingSteps.isNotEmpty)
                ThinkingBubble(
                  steps: group.thinkingSteps,
                  expanded: group.thinkingExpanded,
                  loading: group.loading,
                  onToggle: widget.onToggleThinking ?? () {},
                ),

              if (!isDinqSearch && !isAdvisorSearch && hasCandidates)
                ScholarsList(
                  candidates: group.candidates,
                  groupId: group.id,
                  isLoading: group.loading,
                  onCandidateClick: widget.onCandidateClick,
                ),

              if (isAdvisorSearch && hasAdvisorResults)
                AdvisorsList(advisors: group.advisorResults!),

              // 与 TSX 一致：加载时显示呼吸 Logo（仅 Global/Advisor），pt-2
              if (!isDinqSearch && group.loading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BreathingLogo(
                    size: 24,
                    animation: _breathingController,
                  ),
                ),

              // 与 TSX 一致：有结果且不在加载中时显示操作栏；!isLatest 时整条 opacity-0，悬停 group 时显示
              if (!group.loading &&
                  (hasCandidates || hasDinqResults || hasAdvisorResults)) ...[
                if (widget.isLatest)
                  MessageGroupActionBar(
                    isLatest: true,
                    feedback: _feedback,
                    onFeedbackUp: () =>
                        setState(() => _feedback = _feedback == 'up' ? null : 'up'),
                    onFeedbackDown: () => setState(
                        () => _feedback = _feedback == 'down' ? null : 'down'),
                  )
                else
                  AnimatedOpacity(
                    opacity: _hovering ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: MessageGroupActionBar(
                      isLatest: false,
                      feedback: _feedback,
                      onFeedbackUp: () =>
                          setState(() => _feedback = _feedback == 'up' ? null : 'up'),
                      onFeedbackDown: () => setState(
                          () => _feedback = _feedback == 'down' ? null : 'down'),
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
