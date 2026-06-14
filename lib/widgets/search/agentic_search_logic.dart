import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../stores/search_store.dart';
import '../../utils/parse_quick_replies.dart';
import 'deep_search/deep_search_results_helpers.dart';
import 'deep_search/deep_search_event_handlers.dart';
import 'deep_search/deep_search_models.dart';
import 'deep_search/sub_agent_helpers.dart';
import 'search_box_widget.dart';

/// 单条搜索消息组（与 TSX MessageGroup 对应）
class AgenticMessageGroup {
  AgenticMessageGroup({
    required this.id,
    required this.userQuery,
    this.loading = true,
    this.candidates = const [],
    this.dinqResults,
    this.searchType = 'global',
    List<Map<String, dynamic>>? thinkingSteps,
    this.thinkingExpanded = false,
    this.searchCompleted = false,
    this.advisorResults,
    this.pdfAttachment,
  }) : thinkingSteps = thinkingSteps ?? [];

  final int id;
  final String userQuery;
  bool loading;
  List<Map<String, dynamic>> candidates;
  List<Map<String, dynamic>>? dinqResults;

  /// 'global' | 'dinq' | 'advisor'，与 TSX SearchType 一致（可空以兼容旧实例/热重载）
  final String? searchType;

  /// 与 TSX ThinkingStep[] 一致（可空以兼容旧实例/热重载）
  List<Map<String, dynamic>> thinkingSteps;
  bool thinkingExpanded;

  /// 与 TSX searchCompleted 一致：搜索流是否已结束
  bool searchCompleted;
  List<Map<String, dynamic>>? advisorResults;

  /// { url: string, name: string }，与 TSX pdfAttachment 一致
  Map<String, dynamic>? pdfAttachment;

  /// 流式 llm_end 事件的 message（AI 文字回复）
  String? llmMessage;

  /// 流式 completed 事件的 data.summary
  String? summary;

  /// Deep Search text_delta 累积的 assistant 叙述
  String assistantText = '';

  /// text_delta 流式中
  bool assistantStreaming = false;

  /// 快捷回复已使用（隐藏按钮）
  bool quickRepliesUsed = false;

  /// 是否走 deep-search 事件模型（text_delta / tool_message）
  bool isDeepSearch = false;

  /// Deep Search 工具调用次数（与 TSX toolCount 一致）
  int deepSearchToolCount = 0;

  /// Deep Search 耗时 ms（done 事件 duration_ms）
  int? deepSearchDurationMs;

  /// 与 TSX SearchRound.subAgents 对齐
  Map<String, SubAgentInfo> subAgents = {};

  /// 多 agent fallback 时的 round.contentBlocks
  List<MessagePart> contentBlocks = [];

  /// 与 TSX SearchRound 对齐的扩展字段
  String? errorMessage;
  String? displayQuery;
  String? recordCreatedAt;
  Map<String, dynamic>? toolResult;
  DeepSearchRoundStatus roundStatus = DeepSearchRoundStatus.idle;

  /// 与 TSX round.toolType 对齐（null = deep search）
  String? get toolType {
    switch (searchType) {
      case 'advisor':
        return 'find-advisor';
      case 'citation':
        return 'who-cites-me';
      case 'analyze':
        return 'analysis';
      default:
        return null;
    }
  }
}

/// 与 TSX useAgenticSearch 对应：搜索状态与流式/会话逻辑集中在此文件
class AgenticSearchLogic extends ChangeNotifier {
  AgenticSearchLogic({
    required this.searchService,
    required this.searchStore,
    this.onSearchComplete,
    this.onScrollToBottom,
  });

  final SearchService searchService;
  final SearchStore searchStore;
  final void Function(List<Map<String, dynamic>> candidates, String query)?
  onSearchComplete;
  final VoidCallback? onScrollToBottom;

  List<AgenticMessageGroup> messageGroups = [];
  bool loading = false;
  bool advisorLoading = false;
  bool citationLoading = false;
  bool analysisLoading = false;
  List<Map<String, dynamic>>? analysisCandidates;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _analysisStreamSubscription;
  String? _activeSessionId;

  static List<Map<String, dynamic>> _mergeCandidates(
    List<Map<String, dynamic>> oldList,
    List<Map<String, dynamic>> newList,
  ) {
    return newList.map((newC) {
      final newMap = Map<String, dynamic>.from(newC);
      final rowId = newMap['row_id']?.toString();
      Map<String, dynamic>? existing;
      if (rowId != null && rowId.isNotEmpty) {
        for (final c in oldList) {
          if (c['row_id']?.toString() == rowId) {
            existing = c;
            break;
          }
        }
      }
      final newIndex = newList.indexOf(newC);
      if (existing == null && newIndex < oldList.length) {
        final o = oldList[newIndex];
        if (o['name'] == newMap['name']) existing = o;
      }
      if (existing == null) {
        for (final c in oldList) {
          if (c['name'] == newMap['name']) {
            existing = c;
            break;
          }
        }
      }
      if (existing == null) return newMap;
      final merged = Map<String, dynamic>.from(existing);
      for (final k in newMap.keys) {
        final nv = newMap[k];
        final ov = existing[k];
        if (_valueEquals(ov, nv)) continue;
        merged[k] = nv;
      }
      return merged;
    }).toList();
  }

  static bool _valueEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is List && b is List)
      return a.length == b.length && a.toString() == b.toString();
    return false;
  }

  static int _stepIdCounter = 0;
  static String _generateStepId() => 'step-${++_stepIdCounter}';

  /// 与 TSX normalizeSources 一致
  static List<Map<String, dynamic>> _normalizeSources(dynamic sources) {
    if (sources is! List) return [];
    return sources.map<Map<String, dynamic>>((s) {
      if (s is Map<String, dynamic>) return Map<String, dynamic>.from(s);
      if (s is String) return {'url': s, 'description': ''};
      return <String, dynamic>{};
    }).toList();
  }

  /// 与 TSX getInputType 一致
  static String _getInputType(String input, String? toolName) {
    if (toolName == 'read_file') return 'file';
    if (toolName == 'execute_paper_search_code') return 'query';
    if (input.contains("'url'") || input.contains('"url"')) return 'url';
    if (input.contains("'query'") || input.contains('"query"')) return 'query';
    return 'query';
  }

  /// 与 TSX getInputValue 一致
  /// 与 TSX getInputValue 一致：先 JSON.parse，失败则用正则提取 key 对应的 quoted 值
  static String? _getInputValue(String input, String inputType) {
    if (inputType == 'file') return null;
    try {
      final parsed = jsonDecode(input) as Map<String, dynamic>?;
      if (parsed != null) {
        final v = parsed['query'] ?? parsed['url'];
        return v != null ? v.toString() : null;
      }
      return null;
    } catch (_) {
      final key = inputType == 'query' ? 'query' : 'url';
      return _extractQuoted(input, key);
    }
  }

  static String? _extractQuoted(String input, String key) {
    final pattern = RegExp("['\"]$key['\"]\\s*:\\s*['\"]([^'\"]+)['\"]");
    final m = pattern.firstMatch(input);
    return m?.group(1);
  }

  /// 与 TSX shouldIgnore（llm_end）一致
  /// 与 TSX attachmentPreviewFromUrl 一致
  static Map<String, dynamic>? attachmentFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    var pathname = trimmed;
    try {
      pathname = Uri.parse(trimmed).path;
    } catch (_) {}
    final segments = pathname.split('/').where((s) => s.isNotEmpty).toList();
    final rawName = segments.isNotEmpty ? segments.last : 'Attachment';
    final name = Uri.decodeComponent(rawName);
    return {'url': trimmed, 'name': name};
  }

  static bool _shouldIgnoreLlmMessage(String? message) {
    if (message == null || message.trim().isEmpty) return true;
    const exactMatch = ['done', 'ok', 'success'];
    const partialMatch = ['llm response received', 'processing...'];
    final msg = message.trim().toLowerCase();
    if (exactMatch.contains(msg)) return true;
    for (final p in partialMatch) {
      if (msg.contains(p)) return true;
    }
    return false;
  }

  void _markPendingToolCallsCompleted(int groupId) {
    final idx = messageGroups.indexWhere((g) => g.id == groupId);
    if (idx < 0) return;
    final g = messageGroups[idx];
    g.thinkingSteps = g.thinkingSteps.map((s) {
      if (s['type'] == 'tool_call' && s['completed'] != true) {
        final m = Map<String, dynamic>.from(s);
        m['completed'] = true;
        return m;
      }
      return s;
    }).toList();
    notifyListeners();
  }

  void _addThinkingStep(int groupId, Map<String, dynamic> step) {
    final idx = messageGroups.indexWhere((g) => g.id == groupId);
    if (idx < 0) return;
    final g = messageGroups[idx];
    final withId = Map<String, dynamic>.from(step);
    withId['id'] ??= _generateStepId();
    g.thinkingSteps = [...g.thinkingSteps, withId];
    notifyListeners();
  }

  /// 与 TSX processStreamEvent 一致：处理 discover 流事件
  void _processStreamEvent(int groupId, Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == null) return;

    final idx = messageGroups.indexWhere((g) => g.id == groupId);
    if (idx < 0) return;
    final g = messageGroups[idx];
    // Deep Search 走 text_delta / tool_message，不走 legacy thinkingSteps
    if (g.isDeepSearch) return;
    if (g.searchCompleted) return;

    switch (type) {
      case 'started':
        g.thinkingExpanded = true;
        notifyListeners();
        break;

      case 'llm_start':
        g.thinkingSteps = g.thinkingSteps.map((s) {
          if (s['type'] == 'tool_call' && s['completed'] != true) {
            final m = Map<String, dynamic>.from(s);
            m['completed'] = true;
            return m;
          }
          return s;
        }).toList();
        g.thinkingSteps.add({
          'id': _generateStepId(),
          'type': 'thinking',
          'content': 'Processing...',
          'completed': false,
        });
        notifyListeners();
        break;

      case 'llm_end':
        {
          final message = event['message']?.toString().trim();
          g.thinkingSteps = g.thinkingSteps.map((s) {
            if (s['type'] == 'tool_call' && s['completed'] != true) {
              final m = Map<String, dynamic>.from(s);
              m['completed'] = true;
              return m;
            }
            return s;
          }).toList();
          g.thinkingSteps = g.thinkingSteps
              .where(
                (s) =>
                    !(s['content'] == 'Processing...' &&
                        s['completed'] != true),
              )
              .toList();
          if (!_shouldIgnoreLlmMessage(message) &&
              message != null &&
              message.isNotEmpty) {
            g.assistantText = g.assistantText.isEmpty ? message : g.assistantText;
            g.thinkingSteps.add({
              'id': _generateStepId(),
              'type': 'thinking',
              'content': message,
              'sources': _normalizeSources(event['sources']),
              'completed': true,
            });
          }
          notifyListeners();
          break;
        }

      case 'tool_call':
        {
          final toolName = event['tool_name'] as String?;
          final data = event['data'];
          final input = data is Map ? data['input']?.toString() : null;

          if (toolName == 'write_todos' && input != null && input.isNotEmpty) {
            _markPendingToolCallsCompleted(groupId);
            _addThinkingStep(groupId, {
              'type': 'todo',
              'content': input,
              'action': toolName,
              'completed': true,
            });
            return;
          }
          if (input == null || input.isEmpty) return;

          final inputType = _getInputType(input, toolName);
          final inputValue = _getInputValue(input, inputType);
          final steps = g.thinkingSteps;
          if (steps.isEmpty) {
            g.thinkingSteps = [
              ...steps,
              {
                'id': _generateStepId(),
                'type': 'tool_call',
                'content': input,
                'action': toolName ?? '',
                'completed': false,
                'inputType': inputType,
                'inputs': inputValue != null ? [inputValue] : [],
              },
            ];
          } else {
            final last = steps.last;
            if (last['type'] == 'tool_call' &&
                last['completed'] != true &&
                last['inputType'] == inputType) {
              final prevInputs =
                  (last['inputs'] as List<dynamic>?)?.cast<String>() ?? [];
              final newInputs = [
                ...prevInputs,
                if (inputValue != null) inputValue,
              ].where((e) => e.isNotEmpty).toList();
              g.thinkingSteps = [
                ...steps.sublist(0, steps.length - 1),
                {...last, 'inputs': newInputs},
              ];
            } else {
              g.thinkingSteps = [
                ...steps,
                {
                  'id': _generateStepId(),
                  'type': 'tool_call',
                  'content': input,
                  'action': toolName ?? '',
                  'completed': false,
                  'inputType': inputType,
                  'inputs': inputValue != null ? [inputValue] : [],
                },
              ];
            }
          }
          notifyListeners();
          break;
        }

      case 'tool_result':
        if (event['tool_name'] == 'write_todos') return;
        final steps = g.thinkingSteps;
        for (var i = steps.length - 1; i >= 0; i--) {
          if (steps[i]['type'] == 'tool_call' &&
              steps[i]['completed'] != true) {
            final prev = steps[i];
            final prevSources =
                (prev['sources'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final newSources = _normalizeSources(event['sources']);
            g.thinkingSteps = [
              ...steps.sublist(0, i),
              {
                ...prev,
                'sources': [...prevSources, ...newSources],
              },
              ...steps.sublist(i + 1),
            ];
            notifyListeners();
            return;
          }
        }
        break;

      case 'current_results':
        {
          if (g.isDeepSearch) return;
          final data = event['data'];
          final scholars = data is Map ? data['scholars'] : null;
          if (scholars is! List) return;
          final newCandidates = scholars
              .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
              .toList();
          final merged = _mergeCandidates(g.candidates, newCandidates);
          g.candidates = merged;
          if (searchStore.openTabs.isEmpty) {
            searchStore.setTabsFromCandidates(merged);
          } else {
            searchStore.syncCandidatesToTabs(merged);
          }
          notifyListeners();
          break;
        }

      case 'search_completed':
        g.searchCompleted = true;
        g.loading = false;
        g.thinkingSteps = g.thinkingSteps.map((s) {
          final m = Map<String, dynamic>.from(s);
          m['completed'] = true;
          return m;
        }).toList();
        notifyListeners();
        break;
    }
  }

  /// 与 TSX dispatchStreamEvent 中 deep-search 事件一致
  void _processDeepSearchEvent(int groupId, Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == null) return;

    final idx = messageGroups.indexWhere((g) => g.id == groupId);
    if (idx < 0) return;
    final g = messageGroups[idx];
    if (g.searchCompleted && type != 'done' && type != 'error') return;

    if (!g.isDeepSearch) {
      g.isDeepSearch = true;
      g.thinkingSteps = [];
    }

    final dispatcher = DeepSearchEventDispatcher(
      subAgents: g.subAgents,
      contentBlocks: g.contentBlocks,
      onCandidatesChanged: (candidates) {
        g.candidates = candidates;
        g.quickRepliesUsed = true;
        final tabCandidates = candidates.map(candidateRowToTabCandidate).toList();
        if (searchStore.openTabs.isEmpty) {
          searchStore.setTabsFromCandidates(tabCandidates);
        } else {
          searchStore.syncCandidatesToTabs(tabCandidates);
        }
      },
      onSessionId: (sessionId) {
        if (sessionId.isNotEmpty) _activeSessionId = sessionId;
      },
      onDurationMs: (ms) => g.deepSearchDurationMs = ms,
      onError: (message) {
        g.errorMessage = message;
        g.roundStatus = DeepSearchRoundStatus.error;
        if (g.assistantText.isEmpty) g.assistantText = message;
      },
      onStatusChange: (status) {
        g.roundStatus = status;
        switch (status) {
          case DeepSearchRoundStatus.searching:
            g.loading = true;
            g.assistantStreaming = true;
          case DeepSearchRoundStatus.done:
            g.searchCompleted = true;
            g.loading = false;
            g.assistantStreaming = false;
            g.thinkingSteps = [];
          case DeepSearchRoundStatus.error:
          case DeepSearchRoundStatus.interrupted:
            g.searchCompleted = true;
            g.loading = false;
            g.assistantStreaming = false;
          case DeepSearchRoundStatus.idle:
            break;
        }
      },
    )..setCandidates(g.candidates);

    dispatcher.dispatch(event);
    g.subAgents = dispatcher.subAgents;
    g.contentBlocks = dispatcher.contentBlocks;
    g.deepSearchToolCount = countToolCalls(
      g.subAgents[virtualAgentId]?.contentBlocks ?? g.contentBlocks,
    );

    if (type == 'text_delta') {
      g.assistantStreaming = true;
    } else if (type == 'text' || type == 'done') {
      g.assistantStreaming = false;
    }

    final summaryText = getSingleAgentSummaryText(g.subAgents);
    if (summaryText.isNotEmpty) {
      g.assistantText = summaryText;
    } else if (type == 'text_delta') {
      g.assistantText += event['content']?.toString() ?? '';
    }

    if (type == 'session' || type == 'session_meta') {
      final convId = event['conversation_id'] ?? event['session_id'];
      if (convId != null) {
        final id = convId is int ? convId : int.tryParse(convId.toString());
        if (id != null) searchStore.setCurrentConversationId(id);
      }
    }

    notifyListeners();
  }

  void _replayDeepSearchEvents(AgenticMessageGroup group, List<dynamic> sseEvents) {
    final dispatcher = DeepSearchEventDispatcher(
      subAgents: group.subAgents,
      contentBlocks: group.contentBlocks,
      onCandidatesChanged: (candidates) {
        group.candidates = candidates;
      },
      onDurationMs: (ms) => group.deepSearchDurationMs = ms,
      onStatusChange: (status) {
        if (status == DeepSearchRoundStatus.done) {
          group.searchCompleted = true;
          group.loading = false;
        }
      },
    )..setCandidates(group.candidates);

    for (final ev in sseEvents) {
      if (ev is! Map) continue;
      dispatcher.dispatchHistoryEvent(Map<String, dynamic>.from(ev));
    }
    dispatcher.finalizeHistoryReplay();

    group.subAgents = dispatcher.subAgents;
    group.contentBlocks = dispatcher.contentBlocks;
    group.isDeepSearch = group.subAgents.isNotEmpty;
    group.deepSearchToolCount = countToolCalls(
      group.subAgents[virtualAgentId]?.contentBlocks ?? group.contentBlocks,
    );
    final summaryText = getSingleAgentSummaryText(group.subAgents);
    if (summaryText.isNotEmpty) {
      group.assistantText = summaryText;
    } else if (group.assistantText.isEmpty) {
      group.assistantText = dispatcher.candidates.isNotEmpty
          ? ''
          : group.assistantText;
    }
  }

  /// 与 TSX restoreDiscover SSE 回放一致
  ({String assistantText, List<Map<String, dynamic>> candidates, bool isDeepSearch, int toolCount, int? durationMs})
  _replaySseEvents(List<dynamic> sseEvents) {
    var text = '';
    var isDeep = false;
    var toolCount = 0;
    int? durationMs;
    final rows = <Map<String, dynamic>>[];

    for (final ev in sseEvents) {
      if (ev is! Map) continue;
      final type = ev['type']?.toString();
      switch (type) {
        case 'text_delta':
          isDeep = true;
          text += ev['content']?.toString() ?? '';
          break;
        case 'text':
          isDeep = true;
          final content = ev['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            if (text.isEmpty) {
              text = content;
            } else if (!text.endsWith('\n\n')) {
              text = '${text.trimRight()}\n\n$content';
            } else {
              text += content;
            }
          } else if (text.isNotEmpty && !text.endsWith('\n\n')) {
            text = '${text.trimRight()}\n\n';
          }
          break;
        case 'tool_use':
        case 'tool_result':
          isDeep = true;
          if (type == 'tool_use') toolCount += 1;
          break;
        case 'tool_call':
          {
            final toolName = ev['tool_name']?.toString() ?? '';
            if (toolName.contains('mcp__') || toolName.contains('talent_search')) {
              isDeep = true;
              toolCount += 1;
            }
            break;
          }
        case 'session':
        case 'session_meta':
          isDeep = true;
          break;
        case 'done':
          isDeep = true;
          final d = ev['duration_ms'];
          if (d is int) {
            durationMs = d;
          } else if (d != null) {
            durationMs = int.tryParse(d.toString());
          }
          break;
        case 'tool_message':
          isDeep = true;
          final data = ev['data'];
          if (data is Map && data['action']?.toString() == 'add_row') {
            final row = data['row'];
            if (row is Map) {
              rows.add(Map<String, dynamic>.from(row));
            }
          }
          break;
        case 'llm_end':
          final message = ev['message']?.toString().trim() ?? '';
          if (!_shouldIgnoreLlmMessage(message) && message.isNotEmpty) {
            if (text.isEmpty) text = message;
          }
          break;
        default:
          break;
      }
    }

    return (
      assistantText: text,
      candidates: rows,
      isDeepSearch: isDeep,
      toolCount: toolCount,
      durationMs: durationMs,
    );
  }

  /// 将 sse_events 转为 thinkingSteps（与 TSX convertSseEventsToThinkingSteps 一致）
  List<Map<String, dynamic>> _convertSseEventsToThinkingSteps(
    List<dynamic>? sseEvents,
    int groupId,
  ) {
    debugPrint('sseEvents7777: $sseEvents');
    if (sseEvents == null || sseEvents.isEmpty) return [];
    const exactMatch = ['done', 'ok', 'success'];
    const partialMatch = ['llm response received', 'processing...'];
    final steps = <Map<String, dynamic>>[];
    var stepIndex = 0;

    for (final ev in sseEvents) {
      if (ev is! Map<String, dynamic>) continue;
      final type = ev['type'] as String?;
      switch (type) {
        case 'llm_end':
          {
            final message = ev['message']?.toString().trim() ?? '';
            final msg = message.toLowerCase();
            final shouldIgnore =
                message.isEmpty ||
                exactMatch.contains(msg) ||
                partialMatch.any((m) => msg.contains(m));
            if (!shouldIgnore) {
              steps.add({
                'id': 'history-$groupId-$stepIndex',
                'type': 'thinking',
                'content': message,
                'sources': _normalizeSources(ev['sources']),
                'completed': true,
              });
              stepIndex++;
            }
            break;
          }
        case 'tool_call':
          {
            if (ev['tool_name'] == 'write_todos') break;
            final data = ev['data'];
            if (data is! Map<String, dynamic>) break;
            final input = data['input']?.toString();
            if (input == null || input.isEmpty) break;
            final toolName = ev['tool_name'] as String?;
            
            final inputType = _getInputType(input, toolName);
            final inputValue = _getInputValue(input, inputType);
            final lastStep = steps.isNotEmpty ? steps.last : null;
            debugPrint('input6666: $input');
            debugPrint('inputValue6666: $inputValue');
            if (lastStep != null &&
                lastStep['type'] == 'tool_call' &&
                lastStep['inputType'] == inputType) {
              final inputs =
                  (lastStep['inputs'] as List<dynamic>?)?.cast<String>() ?? [];
              lastStep['inputs'] = [
                ...inputs,
                if (inputValue != null) inputValue,
              ].where((e) => e.isNotEmpty).toList();
            } else {
              steps.add({
                'id': 'history-$groupId-$stepIndex',
                'type': 'tool_call',
                'content': input,
                'action': toolName ?? '',
                'completed': true,
                'inputType': inputType,
                'inputs': inputValue != null ? [inputValue] : [],
              });
              stepIndex++;
            }
            break;
          }
        case 'tool_result':
          if (ev['tool_name'] == 'write_todos') break;
          for (var i = steps.length - 1; i >= 0; i--) {
            if (steps[i]['type'] == 'tool_call') {
              final prev = steps[i];
              final prevSources =
                  (prev['sources'] as List<dynamic>?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];
              prev['sources'] = [
                ...prevSources,
                ..._normalizeSources(ev['sources']),
              ];
              break;
            }
          }
          break;
        default:
          break;
      }
    }
    return steps;
  }

  /// 与 TSX restoreConversation / loadFromConversation 一致
  void loadFromConversation(Map<String, dynamic> conversation) {
    final records = conversation['records'];
    if (records is! List) return;

    final convType =
        (conversation['type'] as String?) ?? searchStore.extraType ?? 'discover';

    final convId = conversation['session_id'] ?? conversation['id'];
    if (convId != null) {
      _activeSessionId = convId.toString();
      final id = convId is int ? convId : int.tryParse(convId.toString());
      if (id != null) searchStore.setCurrentConversationId(id);
    }

    // 与 dinq-client restoreMatch / restoreCitation / restoreAnalyze 对齐 activeTool
    switch (convType) {
      case 'match':
        searchStore.setActiveTool('find-advisor');
        break;
      case 'citation':
        searchStore.setActiveTool('who-cites-me');
        break;
      case 'analyze':
        searchStore.setActiveTool('analysis');
        break;
      default:
        searchStore.clearActiveTool();
    }

    final groups = <AgenticMessageGroup>[];
    for (final r in records) {
      if (r is! Map<String, dynamic>) continue;
      final id = r['id'];
      final rawQuery = r['query'];
      final query = rawQuery is String
          ? rawQuery
          : (rawQuery is Map ? rawQuery['name']?.toString() : null) ??
                conversation['title']?.toString() ??
                '';
      final searchType = r['search_type'] as String?;
      final result = r['result'];
      final sseEvents = r['sse_events'] as List<dynamic>?;
      final summary = r['summary'] as String?;

      List<Map<String, dynamic>> candidates = [];
      List<Map<String, dynamic>>? dinqResults;
      List<Map<String, dynamic>>? advisorResults;
      Map<String, dynamic>? pdfAttachment;

      if (convType == 'match' && result is Map<String, dynamic>) {
        final advisors = result['advisors'];
        if (advisors is List) {
          advisorResults = advisors
              .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
              .toList();
        }
        final pdf = result['pdfAttachment'];
        if (pdf is Map<String, dynamic>) {
          pdfAttachment = Map<String, dynamic>.from(pdf);
        }
      } else if (result is List) {
        final list = result
            .map(
              (e) => e is Map<String, dynamic>
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{},
            )
            .where((m) => m.isNotEmpty)
            .toList();
        if (searchType == 'people_search') {
          dinqResults = list;
        } else {
          candidates = list;
        }
      }

      final groupId = id is int
          ? id
          : (id != null ? int.tryParse(id.toString()) : null) ?? 0;

      String st;
      if (convType == 'match') {
        st = 'advisor';
      } else if (convType == 'analyze') {
        st = 'analyze';
      } else if (convType == 'citation') {
        st = 'citation';
      } else if (searchType == 'people_search') {
        st = 'dinq';
      } else {
        st = searchType ?? 'global';
      }

      List<Map<String, dynamic>> thinkingSteps;
      String assistantText = '';
      bool isDeepSearch = false;
      var deepSearchToolCount = 0;
      int? deepSearchDurationMs;

      if (sseEvents != null && sseEvents.isNotEmpty) {
        final replay = _replaySseEvents(sseEvents);
        assistantText = replay.assistantText;
        isDeepSearch = replay.isDeepSearch;
        deepSearchToolCount = replay.toolCount;
        deepSearchDurationMs = replay.durationMs;
        // candidates 由 _replayDeepSearchEvents 从 sse_events 重建，避免与 _replaySseEvents 重复
        thinkingSteps = isDeepSearch
            ? []
            : _convertSseEventsToThinkingSteps(sseEvents, groupId);
      } else if (summary != null && summary.trim().isNotEmpty) {
        assistantText = summary.trim();
        thinkingSteps = [
          {
            'id': 'history-summary-$groupId',
            'type': 'thinking',
            'content': summary.trim(),
            'completed': true,
          },
        ];
      } else if (convType == 'citation' && result != null) {
        thinkingSteps = [
          {
            'id': 'history-citation-$groupId',
            'type': 'thinking',
            'content': 'Citation results loaded from history.',
            'completed': true,
          },
        ];
      } else {
        thinkingSteps = [];
      }

      final attachment = r['attachment'];
      if (pdfAttachment == null && attachment is String && attachment.isNotEmpty) {
        pdfAttachment = attachmentFromUrl(attachment);
      }

      final group = AgenticMessageGroup(
        id: groupId,
        userQuery: query,
        loading: false,
        candidates: candidates,
        dinqResults: dinqResults,
        searchType: st,
        thinkingSteps: thinkingSteps,
        thinkingExpanded: false,
        searchCompleted: true,
        advisorResults: advisorResults,
        pdfAttachment: pdfAttachment,
      );
      group.assistantText = assistantText;
      group.isDeepSearch = isDeepSearch;
      group.deepSearchToolCount = deepSearchToolCount;
      group.deepSearchDurationMs = deepSearchDurationMs;

      if (convType == 'analyze' && result is Map) {
        final cards = <String, dynamic>{};
        for (final entry in result.entries) {
          final key = entry.key.toString().replaceAll(RegExp(r'_card$'), '');
          cards[key] = {
            'status': 'completed',
            'data': entry.value,
          };
        }
        group.toolResult = {
          'platform': r['source']?.toString() ?? 'scholar',
          'cards': cards,
          'query': query,
          'progress': 100,
          'rounds': [
            {'phase': null},
          ],
        };
        group.roundStatus = DeepSearchRoundStatus.done;
      } else if (convType == 'citation') {
        group.toolResult = {'phase': null, 'data': result};
        group.roundStatus = DeepSearchRoundStatus.done;
      } else if (convType == 'match' && result is Map<String, dynamic>) {
        group.toolResult = {
          'advisors': advisorResults ?? result['advisors'] ?? [],
          'pdfAttachment': result['pdfAttachment'],
          'countries': result['countries'],
          'rounds': [
            {
              'phase': null,
              'advisorCount': result['total_advisors'] ?? advisorResults?.length ?? 0,
            },
          ],
        };
        group.roundStatus = DeepSearchRoundStatus.done;
      }

      if (sseEvents != null &&
          sseEvents.isNotEmpty &&
          (convType == 'discover' || st == 'global')) {
        _replayDeepSearchEvents(group, sseEvents);
        if (group.assistantText.isEmpty && assistantText.isNotEmpty) {
          group.assistantText = assistantText;
        }
        group.deepSearchToolCount = countToolCalls(
          group.subAgents[virtualAgentId]?.contentBlocks ?? group.contentBlocks,
        );
      }

      groups.add(group);
    }

    // 已有后续消息或已搜索的轮次，隐藏快捷回复按钮
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final hasOptions =
          parseQuickReplies(g.assistantText).options.isNotEmpty;
      if (!hasOptions) continue;
      if (i < groups.length - 1) {
        g.quickRepliesUsed = true;
        continue;
      }
      if (g.candidates.isNotEmpty || g.searchCompleted) {
        g.quickRepliesUsed = true;
      }
      if (i > 0) {
        final prev = groups[i - 1];
        final options = parseQuickReplies(prev.assistantText).options;
        if (options.contains(g.userQuery.trim())) {
          prev.quickRepliesUsed = true;
        }
      }
    }

    messageGroups = groups;
    loading = false;
    advisorLoading = false;
    searchStore.loadConversation(conversation);
    notifyListeners();
  }

  /// 与 TSX clearMessages / startNewConversation 一致
  void clearMessages() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _analysisStreamSubscription?.cancel();
    _analysisStreamSubscription = null;
    _activeSessionId = null;
    searchStore.setCurrentConversationId(null);
    messageGroups = [];
    loading = false;
    advisorLoading = false;
    citationLoading = false;
    analysisLoading = false;
    analysisCandidates = null;
    notifyListeners();
  }

  /// 与 TSX handleSearch 一致
  void handleSearch({
    required String query,
    bool simple = false,
    String? attachmentUrl,
    String? attachmentName,
  }) {
    final trimmedQuery = query.trim();
    final attachment = attachmentUrl?.trim();
    if (trimmedQuery.isEmpty && (attachment == null || attachment.isEmpty)) return;

    searchStore.setIsSearching(true);
    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: trimmedQuery.isNotEmpty
          ? trimmedQuery
          : (attachmentName ?? 'Attachment'),
      loading: true,
      candidates: [],
      searchType: 'global',
      thinkingSteps: [],
      thinkingExpanded: false,
      searchCompleted: false,
      pdfAttachment: attachment != null && attachment.isNotEmpty
          ? {
              'url': attachment,
              'name': attachmentName ??
                  attachmentFromUrl(attachment)?['name'] ??
                  'Attachment',
            }
          : null,
    );

    messageGroups = [...messageGroups, group];
    loading = true;
    notifyListeners();

    final stream = searchService.chatStream(
      query: trimmedQuery.isNotEmpty ? trimmedQuery : null,
      mode: simple ? 'fast' : 'research',
      conversationId: searchStore.currentConversationId,
      sessionId: _activeSessionId,
      attachment: attachment,
    );

    _streamSubscription?.cancel();
    _streamSubscription = stream.listen(
      (event) {
        final type = event['type'] as String?;
        if (type == null) return;

        switch (type) {
          case 'text_delta':
          case 'text':
          case 'session':
          case 'session_meta':
          case 'tool_message':
          case 'tool_use':
          case 'tool_result':
          case 'thinking_delta':
          case 'thinking':
          case 'subagent_start':
          case 'subagent_event':
          case 'subagent_end':
          case 'done':
          case 'error':
          case 'status':
          case 'system':
          case 'interrupted':
            _processDeepSearchEvent(groupId, event);
            break;
          case 'started':
          case 'llm_start':
          case 'llm_end':
          case 'tool_call':
          case 'current_results':
          case 'search_completed':
            _processStreamEvent(groupId, event);
            break;
          case 'completed':
            // 流结束补充：合并 data.scholars / data.summary（TSX 无此分支，保留兼容）
            final idx = messageGroups.indexWhere((g) => g.id == groupId);
            if (idx >= 0) {
              final data = event['data'];
              if (data is Map) {
                final scholars = data['scholars'] ?? data['profile'];
                if (scholars is List && scholars.isNotEmpty) {
                  final newCandidates = scholars
                      .map(
                        (e) => Map<String, dynamic>.from(
                          e as Map<String, dynamic>,
                        ),
                      )
                      .toList();
                  final merged = _mergeCandidates(
                    messageGroups[idx].candidates,
                    newCandidates,
                  );
                  messageGroups[idx].candidates = merged;
                  if (searchStore.openTabs.isEmpty) {
                    searchStore.setTabsFromCandidates(merged);
                  } else {
                    searchStore.syncCandidatesToTabs(merged);
                  }
                }
                final summaryStr = data['summary'];
                if (summaryStr != null &&
                    summaryStr.toString().trim().isNotEmpty) {
                  messageGroups[idx].summary = summaryStr.toString().trim();
                }
              }
              messageGroups[idx].loading = false;
              if (messageGroups[idx].isDeepSearch) {
                messageGroups[idx].thinkingSteps = [];
              }
            }
            notifyListeners();
            break;
          default:
            break;
        }

        // 从 started 事件取 conversation_id（与 TSX 一致）
        if (type == 'started') {
          final data = event['data'];
          if (data is Map) {
            final convId = data['conversation_id'] ?? data['session_id'];
            final sessionId = data['session_id'];
            if (sessionId != null && sessionId.toString().trim().isNotEmpty) {
              _activeSessionId = sessionId.toString();
            }
            if (convId != null) {
              final id = convId is int
                  ? convId
                  : int.tryParse(convId.toString());
              if (id != null) searchStore.setCurrentConversationId(id);
            }
          }
        }
      },
      onDone: () {
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        final finalCandidates = idx >= 0
            ? messageGroups[idx].candidates
            : <Map<String, dynamic>>[];
        loading = false;
        if (idx >= 0) {
          messageGroups[idx].loading = false;
          messageGroups[idx].assistantStreaming = false;
        }
        final finalQuery = idx >= 0 ? messageGroups[idx].userQuery : trimmedQuery;
        onSearchComplete?.call(finalCandidates, finalQuery);
        searchStore.setIsSearching(false);
        notifyListeners();
        Future.delayed(
          const Duration(milliseconds: 100),
          () => onScrollToBottom?.call(),
        );

        // 与 TSX 一致：搜索完成后延迟 1 秒折叠 ThinkingBubble（仅当有候选人时）
        if (idx >= 0 && messageGroups[idx].candidates.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            final i = messageGroups.indexWhere((g) => g.id == groupId);
            if (i >= 0) {
              messageGroups[i].thinkingExpanded = false;
              notifyListeners();
            }
          });
        }
      },
      onError: (e, st) {
        loading = false;
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        if (idx >= 0) messageGroups[idx].loading = false;
        searchStore.setIsSearching(false);
        notifyListeners();
      },
    );
  }

  void markQuickRepliesUsed(int groupId) {
    final idx = messageGroups.indexWhere((g) => g.id == groupId);
    if (idx < 0) return;
    messageGroups[idx].quickRepliesUsed = true;
    notifyListeners();
  }

  /// 与 TSX handleDinqSearch 一致
  Future<void> handleDinqSearch(String query) async {
    if (query.trim().isEmpty) return;

    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: query.trim(),
      loading: true,
      candidates: [],
      dinqResults: [],
      searchType: 'dinq',
    );

    messageGroups = [...messageGroups, group];
    loading = true;
    notifyListeners();

    try {
      final response = await searchService.searchUsers({
        'query': query.trim(),
        'limit': 15,
        if (searchStore.currentConversationId != null)
          'conversation_id': searchStore.currentConversationId,
      });
      final results = response['results'];
      final convId = response['conversation_id'];
      if (convId != null) {
        final id = convId is int ? convId : int.tryParse(convId.toString());
        if (id != null) searchStore.setCurrentConversationId(id);
      }
      final list = results is List
          ? results
                .map(
                  (e) => Map<String, dynamic>.from(e as Map<String, dynamic>),
                )
                .toList()
          : <Map<String, dynamic>>[];
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        messageGroups[idx].loading = false;
        messageGroups[idx].dinqResults = list;
        messageGroups[idx].searchCompleted = true;
      }
    } catch (_) {
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        messageGroups[idx].loading = false;
        messageGroups[idx].searchCompleted = true;
      }
    } finally {
      loading = false;
      notifyListeners();
      onScrollToBottom?.call();
    }
  }

  /// 与 TSX handleAdvisorSearch 一致
  void handleAdvisorSearch(AdvisorFormData data) {
    if (data.resumeUrl.trim().isEmpty) return;

    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: data.additionalInfo.trim().isNotEmpty
          ? data.additionalInfo.trim()
          : 'Find advisors for my resume',
      loading: true,
      candidates: const [],
      advisorResults: const [],
      searchType: 'advisor',
      thinkingSteps: const [],
      thinkingExpanded: true,
      searchCompleted: false,
      pdfAttachment: {
        'url': data.resumeUrl,
        'name': data.resumeName ?? 'Resume.pdf',
      },
    );

    messageGroups = [...messageGroups, group];
    advisorLoading = true;
    notifyListeners();

    final stream = searchService.advisorRecommendStream(
      resumeUrl: data.resumeUrl,
      additionalInfo: data.additionalInfo,
      preferredCountries: data.countries,
      maxAdvisors: data.maxAdvisors,
    );

    _streamSubscription?.cancel();
    _streamSubscription = stream.listen(
      (event) {
        final type = event['type'] as String?;
        if (type == null) return;
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        if (idx < 0) return;
        final g = messageGroups[idx];

        switch (type) {
          case 'tool_call':
            {
              final toolName = event['tool_name']?.toString();
              if (toolName != null && toolName.isNotEmpty) {
                _addThinkingStep(groupId, {
                  'type': 'tool_call',
                  'content': toolName,
                  'action': toolName,
                  'completed': false,
                });
              }
              break;
            }
          case 'tool_result':
            {
              _markPendingToolCallsCompleted(groupId);
              final sources = _normalizeSources(event['sources']);
              if (sources.isNotEmpty) {
                _addThinkingStep(groupId, {
                  'type': 'thinking',
                  'content': 'Found ${sources.length} source(s)',
                  'sources': sources,
                  'completed': true,
                });
              }
              break;
            }
          case 'completed':
            {
              final data = event['data'];
              final advisors = data is Map ? data['advisors'] : null;
              if (advisors is List) {
                g.advisorResults = advisors
                    .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
                    .toList();
              }
              g.loading = false;
              g.searchCompleted = true;
              _markPendingToolCallsCompleted(groupId);
              notifyListeners();
              break;
            }
          case 'error':
            {
              final message = event['message']?.toString().trim();
              if (message != null && message.isNotEmpty) {
                _addThinkingStep(groupId, {
                  'type': 'thinking',
                  'content': message,
                  'completed': true,
                });
              }
              g.loading = false;
              g.searchCompleted = true;
              _markPendingToolCallsCompleted(groupId);
              notifyListeners();
              break;
            }
          default:
            break;
        }
      },
      onDone: () {
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        if (idx >= 0) {
          messageGroups[idx].loading = false;
          messageGroups[idx].searchCompleted = true;
        }
        advisorLoading = false;
        notifyListeners();
        onScrollToBottom?.call();
      },
      onError: (_, __) {
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        if (idx >= 0) {
          messageGroups[idx].loading = false;
          messageGroups[idx].searchCompleted = true;
        }
        advisorLoading = false;
        notifyListeners();
      },
    );

    onScrollToBottom?.call();
  }

  /// 与 TSX handleCitationSearch 一致
  Future<void> handleCitationSearch({
    required String query,
    CitationMode mode = CitationMode.author,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: 'Who cites $trimmed?',
      loading: true,
      candidates: const [],
      searchType: 'citation',
      thinkingSteps: const [],
      searchCompleted: false,
    );
    group.toolResult = {'phase': 'searching', 'data': null};
    group.roundStatus = DeepSearchRoundStatus.searching;

    messageGroups = [...messageGroups, group];
    citationLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> response;
      if (mode == CitationMode.paper) {
        response = await searchService.getPaperCiters(paperIdentifier: trimmed);
      } else {
        response = await searchService.getScholarCitations(query: trimmed);
      }
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        messageGroups[idx].loading = false;
        messageGroups[idx].searchCompleted = true;
        messageGroups[idx].roundStatus = DeepSearchRoundStatus.done;
        messageGroups[idx].toolResult = {'phase': null, 'data': response};
      }
    } catch (_) {
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        messageGroups[idx].loading = false;
        messageGroups[idx].searchCompleted = true;
        messageGroups[idx].roundStatus = DeepSearchRoundStatus.error;
        messageGroups[idx].errorMessage = 'Citation search failed';
      }
    } finally {
      citationLoading = false;
      notifyListeners();
      onScrollToBottom?.call();
    }
  }

  /// 与 TSX handleAnalysisSearch + scholar/github/linkedinAnalyzeStream 对齐
  Future<void> handleAnalysisSearch({
    required String platform,
    required String query,
    Map<String, dynamic>? candidateData,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final analysisQuery = platform == 'github'
        ? (_extractGitHubUsername(trimmed) ?? trimmed)
        : trimmed;
    if (analysisQuery.isEmpty) return;

    _analysisStreamSubscription?.cancel();
    analysisCandidates = null;

    final lastGroup = messageGroups.isNotEmpty ? messageGroups.last : null;
    final isResuming = lastGroup != null &&
        lastGroup.toolType == 'analysis' &&
        lastGroup.roundStatus != DeepSearchRoundStatus.done &&
        lastGroup.roundStatus != DeepSearchRoundStatus.interrupted;

    final needsResolving = platform == 'scholar' || platform == 'linkedin';
    late final int groupId;

    if (isResuming) {
      groupId = lastGroup.id;
      final existing = Map<String, dynamic>.from(
        lastGroup.toolResult ?? const {},
      );
      final rounds = existing['rounds'] is List
          ? List<Map<String, dynamic>>.from(
              (existing['rounds'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            )
          : <Map<String, dynamic>>[
              {
                'phase': needsResolving ? 'analyzing' : 'analyzing',
              },
            ];
      lastGroup.loading = true;
      lastGroup.searchCompleted = false;
      lastGroup.roundStatus = DeepSearchRoundStatus.searching;
      lastGroup.toolResult = {
        ...existing,
        'platform': platform,
        'query': analysisQuery,
        'cards': existing['cards'] is Map
            ? Map<String, dynamic>.from(existing['cards'] as Map)
            : <String, dynamic>{},
        'progress': existing['progress'] ?? 0,
        'rounds': rounds,
      };
    } else {
      groupId = DateTime.now().millisecondsSinceEpoch;
      final group = AgenticMessageGroup(
        id: groupId,
        userQuery: trimmed,
        loading: true,
        candidates: const [],
        searchType: 'analyze',
        thinkingSteps: const [],
        searchCompleted: false,
      );
      group.roundStatus = DeepSearchRoundStatus.searching;
      group.toolResult = {
        'platform': platform,
        'query': analysisQuery,
        'cards': <String, dynamic>{},
        'progress': 0,
        'rounds': [
          {
            'phase': needsResolving ? 'resolving' : 'analyzing',
          },
        ],
      };
      messageGroups = [...messageGroups, group];
    }

    analysisLoading = true;
    notifyListeners();

    var firstCardSeen = false;

    void updateGroup(void Function(AgenticMessageGroup group, Map<String, dynamic> result) fn) {
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx < 0) return;
      final result = Map<String, dynamic>.from(
        messageGroups[idx].toolResult ?? const {},
      );
      fn(messageGroups[idx], result);
      messageGroups[idx].toolResult = result;
      notifyListeners();
    }

    void setAnalysisPhase(String? phase) {
      updateGroup((group, result) {
        final rounds = result['rounds'] is List
            ? List<Map<String, dynamic>>.from(
                (result['rounds'] as List).map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ),
              )
            : <Map<String, dynamic>>[{'phase': phase}];
        if (rounds.isEmpty) {
          rounds.add({'phase': phase});
        } else {
          final last = Map<String, dynamic>.from(rounds.last);
          if (last['phase']?.toString() != phase) {
            rounds[rounds.length - 1] = {...last, 'phase': phase};
          }
        }
        result['rounds'] = rounds;
        group.toolResult = result;
      });
    }

    void applyAnalysisEvent(Map<String, dynamic> event) {
      final status = event['status']?.toString();
      if (status == 'heartbeat') return;

      if (status == 'need_selection') {
        final candidates = event['candidates'];
        if (candidates is List) {
          analysisCandidates = candidates
              .whereType<Map>()
              .map((c) => Map<String, dynamic>.from(c))
              .map((c) {
                if (platform == 'linkedin') {
                  return {
                    'name': c['title']?.toString() ?? '',
                    'content': c['content']?.toString() ?? '',
                    'subtext': c['url']?.toString() ?? '',
                    'url': c['url']?.toString() ?? '',
                  };
                }
                return {
                  'name': c['name']?.toString() ?? '',
                  'content': c['content']?.toString() ?? '',
                  'subtext': c['scholar_id']?.toString() ?? '',
                  'url': c['url']?.toString() ?? c['scholar_id']?.toString() ?? '',
                  'scholar_id': c['scholar_id']?.toString(),
                };
              })
              .toList();
        }
        updateGroup((group, result) {
          group.loading = false;
          group.searchCompleted = false;
          group.roundStatus = DeepSearchRoundStatus.idle;
          if (event['current_action'] != null) {
            final rounds = result['rounds'] is List
                ? List<Map<String, dynamic>>.from(
                    (result['rounds'] as List).map(
                      (e) => Map<String, dynamic>.from(e as Map),
                    ),
                  )
                : <Map<String, dynamic>>[{}];
            if (rounds.isNotEmpty) {
              rounds[rounds.length - 1] = {
                ...rounds.last,
                'currentAction': event['current_action'],
              };
            }
            result['rounds'] = rounds;
          }
        });
        analysisLoading = false;
        notifyListeners();
        _analysisStreamSubscription?.cancel();
        _analysisStreamSubscription = null;
        return;
      }

      updateGroup((group, result) {
        final progress = event['overall'];
        if (progress is num) {
          result['progress'] = progress.toInt();
        }

        final cards = result['cards'] is Map
            ? Map<String, dynamic>.from(result['cards'] as Map)
            : <String, dynamic>{};
        final eventCards = event['cards'];
        if (eventCards is Map) {
          if (!firstCardSeen) {
            final hasActive = eventCards.values.any((cardInfo) {
              if (cardInfo is! Map) return false;
              final cardStatus = cardInfo['status']?.toString();
              return cardStatus == 'done' || cardStatus == 'error';
            });
            if (hasActive) {
              firstCardSeen = true;
              final rounds = result['rounds'] is List
                  ? List<Map<String, dynamic>>.from(
                      (result['rounds'] as List).map(
                        (e) => Map<String, dynamic>.from(e as Map),
                      ),
                    )
                  : <Map<String, dynamic>>[{'phase': 'analyzing'}];
              if (rounds.isNotEmpty) {
                rounds[rounds.length - 1] = {
                  ...rounds.last,
                  'phase': 'analyzing',
                };
              }
              result['rounds'] = rounds;
            }
          }

          for (final entry in eventCards.entries) {
            final cardInfo = entry.value;
            if (cardInfo is! Map) continue;
            final normalizedName =
                entry.key.toString().replaceAll(RegExp(r'_card$'), '');
            cards[normalizedName] = {
              'status': _normalizeAnalysisCardStatus(cardInfo['status']),
              'data': cardInfo['data'],
              'error': cardInfo['error'],
            };
          }
        }

        final profileData = event['result'];
        if (profileData is Map && profileData['profile_data'] is Map) {
          final existingProfile = cards['profile'];
          final existingData = existingProfile is Map &&
                  existingProfile['data'] is Map
              ? Map<String, dynamic>.from(existingProfile['data'] as Map)
              : <String, dynamic>{};
          cards['profile'] = {
            'status': 'completed',
            'data': {
              ...existingData,
              ...Map<String, dynamic>.from(
                profileData['profile_data'] as Map,
              ),
            },
          };
        }

        if (event['current_action'] != null) {
          final rounds = result['rounds'] is List
              ? List<Map<String, dynamic>>.from(
                  (result['rounds'] as List).map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ),
                )
              : <Map<String, dynamic>>[{}];
          if (rounds.isNotEmpty) {
            rounds[rounds.length - 1] = {
              ...rounds.last,
              'currentAction': event['current_action'],
            };
          }
          result['rounds'] = rounds;
        }

        result['cards'] = cards;
        group.toolResult = result;
      });
    }

    try {
      _analysisStreamSubscription = searchService
          .analyzeStream(
            platform: platform,
            query: analysisQuery,
            candidateData: candidateData,
          )
          .listen(
            applyAnalysisEvent,
            onDone: () {
              setAnalysisPhase(null);
              updateGroup((group, _) {
                group.loading = false;
                group.searchCompleted = true;
                group.roundStatus = DeepSearchRoundStatus.done;
              });
              analysisLoading = false;
              _analysisStreamSubscription = null;
              notifyListeners();
              onScrollToBottom?.call();
            },
            onError: (_, __) {
              updateGroup((group, _) {
                group.loading = false;
                group.searchCompleted = true;
                group.roundStatus = DeepSearchRoundStatus.error;
                group.errorMessage = 'Analysis failed';
              });
              analysisLoading = false;
              _analysisStreamSubscription = null;
              notifyListeners();
            },
          );
    } catch (_) {
      updateGroup((group, _) {
        group.loading = false;
        group.searchCompleted = true;
        group.roundStatus = DeepSearchRoundStatus.error;
        group.errorMessage = 'Analysis failed';
      });
      analysisLoading = false;
      notifyListeners();
    }
  }

  static String _normalizeAnalysisCardStatus(dynamic status) {
    final value = status?.toString();
    if (value == 'done') return 'completed';
    if (value == 'error') return 'failed';
    if (value == 'running') return 'running';
    return 'pending';
  }

  static String? _extractGitHubUsername(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.contains('github.com')) {
      final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.first;
    }
    return trimmed.replaceFirst(RegExp(r'^@'), '');
  }

  void clearAnalysisCandidates() {
    analysisCandidates = null;
    notifyListeners();
  }

  Future<void> _stopServerSearchIfNeeded() async {
    final sid = _activeSessionId;
    if (sid == null || sid.isEmpty) return;
    try {
      await searchService.stopDeepSearch(sid);
    } catch (_) {
      // ignore stop error
    }
  }

  /// 与 TSX handleStop 一致（尽量通知服务端停止）
  void handleStop() {
    unawaited(_stopServerSearchIfNeeded());
    _activeSessionId = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _analysisStreamSubscription?.cancel();
    _analysisStreamSubscription = null;
    searchStore.setIsSearching(false);
    loading = false;
    advisorLoading = false;
    citationLoading = false;
    analysisLoading = false;
    for (final g in messageGroups) {
      if (g.loading) g.loading = false;
    }
    notifyListeners();
  }

  /// 仅清空消息列表与 loading（加载历史会话时先清空以显示骨架屏）
  void clearMessagesOnly() {
    messageGroups = [];
    loading = false;
    notifyListeners();
  }

  /// 与 TSX onToggleThinking 一致：切换指定消息组的思考过程展开状态
  void setThinkingExpanded(int groupId) {
    final idx = messageGroups.indexWhere((g) => g.id == groupId);
    if (idx >= 0) {
      messageGroups[idx].thinkingExpanded =
          !messageGroups[idx].thinkingExpanded;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
