import '../../../utils/parse_quick_replies.dart';
import 'deep_search_models.dart';
import 'trace_strings.dart';

const summaryPrefix = '[summary]';

String normalizeSummaryMarkerCandidate(String text) {
  final trimmed = text.trimLeft();
  return trimmed.startsWith('\\') ? trimmed.substring(1) : trimmed;
}

bool hasSummaryPrefix(String text) =>
    normalizeSummaryMarkerCandidate(text).toLowerCase().startsWith(summaryPrefix);

bool isSummaryPrefixPending(String text) {
  final trimmed = normalizeSummaryMarkerCandidate(text).toLowerCase();
  return trimmed.isNotEmpty &&
      summaryPrefix.startsWith(trimmed) &&
      trimmed.length < summaryPrefix.length;
}

String stripSummaryPrefix(String text) {
  final trimmed = text.trimLeft();
  final withoutEscape =
      trimmed.startsWith('\\') ? trimmed.substring(1) : trimmed;
  if (!withoutEscape.toLowerCase().startsWith(summaryPrefix)) return text;
  return withoutEscape.substring(summaryPrefix.length).replaceFirst(RegExp(r'^\s+'), '');
}

bool isHiddenToolCall(MessagePart part) =>
    part is ToolCallPart && part.block.name == 'ToolSearch';

class ToolGroup {
  ToolGroup({required this.id, this.label, this.tools = const []});

  final String id;
  final String? label;
  final List<ToolCallBlock> tools;
}

sealed class TreeSegment {}

class ThinkingTreeSegment extends TreeSegment {
  ThinkingTreeSegment({required this.id, required this.blocks});
  final String id;
  final List<ThinkingBlock> blocks;
}

class ToolGroupTreeSegment extends TreeSegment {
  ToolGroupTreeSegment({required this.id, required this.group});
  final String id;
  final ToolGroup group;
}

class ClassifiedBlocks {
  ClassifiedBlocks({
    this.initialThinking = const [],
    this.opening,
    this.segments = const [],
    this.summary,
  });

  final List<ThinkingBlock> initialThinking;
  final ReasoningBlock? opening;
  final List<TreeSegment> segments;
  final ReasoningBlock? summary;
}

bool _isMarkedSummaryReasoning(MessagePart part) {
  if (part is! ReasoningPart) return false;
  return hasSummaryPrefix(part.block.text) ||
      isSummaryPrefixPending(part.block.text);
}

ReasoningBlock _cleanSummaryReasoning(ReasoningBlock block) =>
    block.copyWith(text: stripSummaryPrefix(block.text));

bool isCleanLabel(String text) {
  final parsed = parseEnvelope(text);
  if (parsed.type == 'summary' || parsed.type == 'confirm') return false;

  final t = text.trim();
  return t.isNotEmpty &&
      !t.contains('": "') &&
      !t.contains('```') &&
      !t.contains('https://');
}

ClassifiedBlocks classifyBlocks(
  List<MessagePart> blocks, {
  required bool allowFallbackSummary,
}) {
  final structural = blocks.where((b) {
    if (isHiddenToolCall(b)) return false;
    return b is ThinkingPart || b is ReasoningPart || b is ToolCallPart;
  }).toList();

  var idx = 0;
  final initialThinking = <ThinkingBlock>[];
  while (idx < structural.length && structural[idx] is ThinkingPart) {
    initialThinking.add((structural[idx] as ThinkingPart).block);
    idx++;
  }
  var rest = structural.sublist(idx);

  ReasoningBlock? opening;
  if (rest.isNotEmpty &&
      rest.first is ReasoningPart &&
      !_isMarkedSummaryReasoning(rest.first)) {
    var openingIdx = 0;
    var openingBlock = (rest.first as ReasoningPart).block;

    bool hasIncompleteQuickReplies(String text) {
      if (!text.contains('<<')) return false;
      return !RegExp(r'<<[\s\S]+?>>').hasMatch(text);
    }

    while (openingIdx + 1 < rest.length &&
        rest[openingIdx + 1] is ReasoningPart &&
        !_isMarkedSummaryReasoning(rest[openingIdx + 1]) &&
        hasIncompleteQuickReplies(openingBlock.text)) {
      openingIdx++;
      openingBlock = openingBlock.copyWith(
        text: openingBlock.text + (rest[openingIdx] as ReasoningPart).block.text,
      );
    }

    opening = openingBlock;
    rest = rest.sublist(openingIdx + 1);
  }

  ReasoningBlock? summary;
  final markedSummaryIdx =
      rest.indexWhere((b) => _isMarkedSummaryReasoning(b));
  if (markedSummaryIdx >= 0) {
    summary = _cleanSummaryReasoning(
      (rest[markedSummaryIdx] as ReasoningPart).block,
    );
    rest = [...rest]..removeAt(markedSummaryIdx);
  }

  if (rest.isNotEmpty) {
    final last = rest.last;
    if (allowFallbackSummary &&
        summary == null &&
        last is ReasoningPart &&
        !last.block.isStreaming) {
      summary = _cleanSummaryReasoning(last.block);
      rest = rest.sublist(0, rest.length - 1);
    }
  }

  final segments = <TreeSegment>[];
  ToolGroup? currentGroup;
  var currentThinking = <ThinkingBlock>[];

  void flushThinking() {
    if (currentThinking.isNotEmpty) {
      segments.add(
        ThinkingTreeSegment(
          id: currentThinking.first.id,
          blocks: List<ThinkingBlock>.from(currentThinking),
        ),
      );
      currentThinking = [];
    }
  }

  void flushGroup({bool includeEmpty = false}) {
    if (currentGroup != null &&
        (includeEmpty || currentGroup!.tools.isNotEmpty)) {
      segments.add(
        ToolGroupTreeSegment(id: currentGroup!.id, group: currentGroup!),
      );
    }
    currentGroup = null;
  }

  for (final block in rest) {
    if (block is ThinkingPart) {
      flushGroup();
      currentThinking.add(block.block);
    } else if (block is ReasoningPart) {
      if (hasSummaryPrefix(block.block.text)) {
        summary ??= _cleanSummaryReasoning(block.block);
        continue;
      }

      flushThinking();
      flushGroup();
      final label = isCleanLabel(block.block.text) ? block.block.text.trim() : null;
      currentGroup = ToolGroup(id: block.block.id, label: label);
    } else if (block is ToolCallPart) {
      flushThinking();
      if (block.block.name.contains('submit_candidates') &&
          currentGroup != null &&
          currentGroup!.tools.isNotEmpty) {
        flushGroup();
      }
      currentGroup ??= ToolGroup(id: block.block.id);
      currentGroup = ToolGroup(
        id: currentGroup!.id,
        label: currentGroup!.label,
        tools: [...currentGroup!.tools, block.block],
      );
    }
  }
  flushThinking();
  flushGroup(includeEmpty: true);

  return ClassifiedBlocks(
    initialThinking: initialThinking,
    opening: opening,
    segments: segments,
    summary: summary,
  );
}

String getSingleAgentSummaryText(Map<String, SubAgentInfo> subAgents) {
  final virtualAgent = subAgents[virtualAgentId];
  if (virtualAgent == null) return '';
  final classified = classifyBlocks(
    virtualAgent.contentBlocks,
    allowFallbackSummary: virtualAgent.status != DeepSearchRoundStatus.searching,
  );
  return classified.summary?.text.trim() ?? '';
}

int countToolCalls(List<MessagePart> blocks) =>
    blocks.where((b) => b is ToolCallPart && !isHiddenToolCall(b)).length;

const toolTenses = <String, List<String>>{
  'talent_search': ['Searching talent database…', 'Searched talent database'],
  'search_ai_lab_talent': ['Searching AI lab databases…', 'Searched AI lab databases'],
  'search_arxiv_papers': ['Searching arXiv papers…', 'Searched arXiv papers'],
  'search_github_talent': ['Searching GitHub profiles…', 'Searched GitHub profiles'],
  'search_hf_users': ['Searching HuggingFace users…', 'Searched HuggingFace users'],
  'get_github_profile': ['Fetching GitHub profile…', 'Fetched GitHub profile'],
  'get_hf_user_detail': ['Fetching HuggingFace detail…', 'Fetched HuggingFace detail'],
  'search_linkedin_profile': ['Searching LinkedIn…', 'Searched LinkedIn'],
  'search_company': ['Searching companies…', 'Searched companies'],
  'search_people': ['Searching people…', 'Searched people'],
  'search_research_paper': ['Searching research papers…', 'Searched research papers'],
  'search_tweet': ['Searching tweets…', 'Searched tweets'],
  'search_personal_site': ['Searching personal sites…', 'Searched personal sites'],
  'search_news': ['Searching news…', 'Searched news'],
  'search_github': ['Searching GitHub…', 'Searched GitHub'],
  'submit_candidates': ['Submitting candidates…', 'Submitted candidates'],
  'perplexity_search': ['Searching with Perplexity…', 'Searched with Perplexity'],
  'perplexity_ask': ['Asking Perplexity…', 'Asked Perplexity'],
  'perplexity_research': ['Researching with Perplexity…', 'Researched with Perplexity'],
  'brave_web_search': ['Searching the web…', 'Searched the web'],
  'firecrawl_scrape': ['Scraping page…', 'Scraped page'],
  'firecrawl_search': ['Searching with Firecrawl…', 'Searched with Firecrawl'],
  'google_ai_mode_search': ['Searching with Google AI…', 'Searched with Google AI'],
};

String toolDisplayName(String name) {
  final parts = name.split('__');
  return (parts.isNotEmpty ? parts.last : name).replaceAll('_', ' ');
}

String? matchToolKey(String name) {
  for (final key in toolTenses.keys) {
    if (name.contains(key)) return key;
  }
  return null;
}

String toolToGerund(String name) {
  final key = matchToolKey(name);
  return key != null ? toolTenses[key]![0] : 'Running ${toolDisplayName(name)}…';
}

String toolToPast(String name) {
  final key = matchToolKey(name);
  return key != null ? toolTenses[key]![1] : 'Ran ${toolDisplayName(name)}';
}

bool hasToolName(List<ToolCallBlock> tools, List<String> patterns) =>
    tools.any((tool) => patterns.any(tool.name.contains));

String fallbackToolGroupLabel(List<ToolCallBlock> tools) {
  return TraceStrings.groupLabelForKey(fallbackToolGroupLabelKey(tools));
}

String fallbackToolGroupLabelKey(List<ToolCallBlock> tools) {
  if (tools.isEmpty) return 'preparingTools';
  if (hasToolName(tools, ['submit_candidates'])) return 'submittingCandidates';
  if (hasToolName(
    tools,
    ['company_employee', 'talent_search', 'search_ai_lab_talent'],
  )) {
    return 'searchingTalentSources';
  }
  if (hasToolName(
    tools,
    ['search_github_talent', 'search_hf_users', 'search_arxiv_papers'],
  )) {
    return 'searchingTechnicalProfiles';
  }
  if (hasToolName(
    tools,
    [
      'WebSearch',
      'brave_web_search',
      'firecrawl_search',
      'google_ai_mode_search',
      'tavily_web_search',
    ],
  )) {
    return 'searchingWebSources';
  }
  return 'runningTools';
}

String formatDuration(ToolCallBlock block) {
  final end = block.endedAt ?? DateTime.now().millisecondsSinceEpoch;
  final ms = end - block.startedAt;
  if (ms < 2) return '';
  if (ms < 1000) return '${ms}ms';
  return '${(ms / 1000).toStringAsFixed(1)}s';
}

List<String> extractCandidateNames(dynamic input) {
  String raw;
  if (input is String) {
    raw = input;
  } else {
    try {
      raw = input?.toString() ?? '';
    } catch (_) {
      return [];
    }
  }
  raw = raw.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
  final matches = RegExp(r'"name"\s*:\s*"([^"]{2,50})"').allMatches(raw);
  final names = <String>[];
  for (final m in matches) {
    final name = m.group(1)?.trim() ?? '';
    if (name.isEmpty || names.contains(name)) continue;
    if (_looksLikePersonName(name)) names.add(name);
  }
  return names;
}

bool _looksLikePersonName(String s) {
  if (s.contains('/') ||
      s.contains('http') ||
      s.contains('@') ||
      s.contains('{')) {
    return false;
  }
  if (s.contains('.com') || s.contains('.org') || s.contains('_')) {
    return false;
  }
  final words = s.split(RegExp(r'\s+'));
  if (words.length < 2 || words.length > 5) return false;
  return words.every(
    (w) =>
        RegExp(r'^[A-Z\u00C0-\u024F\u4e00-\u9fff]').hasMatch(w) || w.length <= 3,
  );
}

({String? query, int? maxResults}) extractToolQuery(dynamic input) {
  if (input is! Map) return (query: null, maxResults: null);
  final map = Map<String, dynamic>.from(input);
  final maxResults = map['max_results'];
  return (
    query: map['query']?.toString(),
    maxResults: maxResults is int ? maxResults : int.tryParse('$maxResults'),
  );
}

List<String> extractResultUrls(String? result) {
  if (result == null || result.isEmpty) return [];
  final urls = <String>[];
  for (final m in RegExp(r'"profile_url"\s*:\s*"([^"]+)"').allMatches(result)) {
    final url = m.group(1);
    if (url != null && url.isNotEmpty && !urls.contains(url)) urls.add(url);
  }
  return urls.take(3).toList();
}

String urlDomain(String url) {
  try {
    return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
  } catch (_) {
    return url;
  }
}

const thinkingMessages = TraceStrings.thinkingMessages;
const searchingMessages = TraceStrings.searchingMessages;

const sourceLabels = <String, String>{
  'academic-search': TraceStrings.sourceAcademic,
  'tech-talent-search': TraceStrings.sourceTechTalent,
  'web-intelligence': TraceStrings.sourceWebIntel,
};
