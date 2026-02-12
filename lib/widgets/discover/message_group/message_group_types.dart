/// 单条消息组数据（与 TSX MessageGroup 对应）
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
}
