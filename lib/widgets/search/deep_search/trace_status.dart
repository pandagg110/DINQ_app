import '../../../utils/parse_quick_replies.dart';
import 'deep_search_models.dart';

/// 与 TSX `traceStatus.ts` 对齐。

const toolTenseKeys = <String>[
  'talent_search',
  'search_ai_lab_talent',
  'search_arxiv_papers',
  'search_github_talent',
  'search_hf_users',
  'get_github_profile',
  'get_hf_user_detail',
  'search_linkedin_profile',
  'search_company',
  'search_people',
  'search_research_paper',
  'search_tweet',
  'search_personal_site',
  'search_news',
  'search_github',
  'submit_candidates',
  'perplexity_search',
  'perplexity_ask',
  'perplexity_research',
  'brave_web_search',
  'firecrawl_scrape',
  'firecrawl_search',
  'google_ai_mode_search',
];

sealed class LatestTraceStatus {}

class ToolTraceStatus extends LatestTraceStatus {
  ToolTraceStatus({
    required this.toolName,
    required this.toolKey,
    this.query,
    this.maxResults,
  });

  final String toolName;
  final String? toolKey;
  final String? query;
  final int? maxResults;
}

class ThinkingTraceStatus extends LatestTraceStatus {
  ThinkingTraceStatus(this.text);
  final String text;
}

String? matchToolKey(String name) {
  for (final key in toolTenseKeys) {
    if (name.contains(key)) return key;
  }
  return null;
}

String toolDisplayName(String name) {
  final parts = name.split('__');
  return (parts.isNotEmpty ? parts.last : name).replaceAll('_', ' ');
}

bool isHiddenToolCall(ToolCallBlock block) => block.name == 'ToolSearch';

({String? query, int? maxResults}) extractToolQuery(dynamic input) {
  if (input is! Map) return (query: null, maxResults: null);
  final query = input['query']?.toString();
  final maxResults = input['max_results'] is int
      ? input['max_results'] as int
      : int.tryParse(input['max_results']?.toString() ?? '');
  return (query: query, maxResults: maxResults);
}

String _cleanOneLine(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

LatestTraceStatus? getLatestTraceStatus({
  required DeepSearchRoundStatus status,
  required List<MessagePart> contentBlocks,
  required Map<String, SubAgentInfo> subAgents,
}) {
  if (status != DeepSearchRoundStatus.searching) return null;

  final blocks = <MessagePart>[
    ...contentBlocks,
    for (final agent in subAgents.values) ...agent.contentBlocks,
  ];

  for (var i = blocks.length - 1; i >= 0; i--) {
    final part = blocks[i];
    if (part is ToolCallPart && !isHiddenToolCall(part.block)) {
      final extracted = extractToolQuery(part.block.input);
      return ToolTraceStatus(
        toolName: part.block.name,
        toolKey: matchToolKey(part.block.name),
        query: extracted.query,
        maxResults: extracted.maxResults,
      );
    }

    if (part is ThinkingPart) {
      final text = _cleanOneLine(part.block.text);
      if (text.isNotEmpty) return ThinkingTraceStatus(text);
    }

    if (part is ReasoningPart) {
      final text = _cleanOneLine(parseEnvelope(part.block.text).cleanText);
      if (text.isNotEmpty) return ThinkingTraceStatus(text);
    }
  }

  return null;
}
