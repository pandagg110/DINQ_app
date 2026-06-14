import '../deep_search/deep_search_models.dart';

/// 单条消息组数据（与 TSX MessageGroup / SearchRound 对应）
class MessageGroupData {
  const MessageGroupData({
    required this.id,
    required this.userQuery,
    this.loading = true,
    this.candidates = const [],
    this.searchType = 'global',
    this.thinkingSteps = const [],
    this.thinkingExpanded = false,
    this.dinqResults,
    this.advisorResults,
    this.pdfAttachment,
    this.llmMessage,
    this.summary,
    this.assistantText,
    this.assistantStreaming = false,
    this.quickRepliesUsed = false,
    this.isDeepSearch = false,
    this.deepSearchToolCount = 0,
    this.deepSearchDurationMs,
    this.searchCompleted = false,
    this.subAgents = const {},
    this.hideUserQueryBubble = false,
  });

  final int id;
  final String userQuery;
  final bool loading;
  final List<Map<String, dynamic>> candidates;
  /// 'global' | 'dinq' | 'advisor'，与 TSX SearchType 一致
  final String searchType;
  final List<Map<String, dynamic>> thinkingSteps;
  final bool thinkingExpanded;
  final List<Map<String, dynamic>>? dinqResults;
  final List<Map<String, dynamic>>? advisorResults;
  /// { 'url': String, 'name': String }，与 TSX pdfAttachment 一致
  final Map<String, dynamic>? pdfAttachment;
  /// 流式 llm_end 的 message（AI 文字回复）
  final String? llmMessage;
  /// 流式 completed 的 data.summary
  final String? summary;
  /// Deep Search assistant 叙述（text_delta 累积）
  final String? assistantText;
  final bool assistantStreaming;
  final bool quickRepliesUsed;
  /// Deep Search 模式（不展示 legacy ThinkingBubble 工具树）
  final bool isDeepSearch;
  final int deepSearchToolCount;
  final int? deepSearchDurationMs;
  final bool searchCompleted;
  /// 与 TSX SearchRound.subAgents 对齐
  final Map<String, SubAgentInfo> subAgents;
  /// 与 SearchPanel `hideUserQueryBubble` 对齐
  final bool hideUserQueryBubble;
}
