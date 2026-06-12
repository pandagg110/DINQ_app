import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/search_service.dart';
import '../../stores/search_store.dart';

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
  StreamSubscription? _streamSubscription;

  static List<Map<String, dynamic>> _mergeCandidates(
    List<Map<String, dynamic>> oldList,
    List<Map<String, dynamic>> newList,
  ) {
    return newList.asMap().entries.map((entry) {
      final newC = Map<String, dynamic>.from(entry.value);
      final newIndex = entry.key;
      Map<String, dynamic>? existing;
      if (newIndex < oldList.length) {
        final o = oldList[newIndex];
        if (o['name'] == newC['name']) existing = o;
      }
      if (existing == null) {
        for (final c in oldList) {
          if (c['name'] == newC['name']) {
            existing = c;
            break;
          }
        }
      }
      if (existing == null) return newC;
      final merged = Map<String, dynamic>.from(existing);
      for (final k in newC.keys) {
        final nv = newC[k];
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

  /// 与 TSX loadFromConversation 一致（含 recordToMessageGroup：sse_events -> thinkingSteps，searchCompleted: true）
  void loadFromConversation(Map<String, dynamic> conversation) {
    final records = conversation['records'];
    if (records is! List) return;
    final convId = conversation['id'];
    if (convId != null) {
      final id = convId is int ? convId : int.tryParse(convId.toString());
      if (id != null) searchStore.setCurrentConversationId(id);
    }
    final groups = <AgenticMessageGroup>[];
    for (final r in records) {
      if (r is! Map<String, dynamic>) continue;
      final id = r['id'];
      final query = r['query'] as String? ?? '';
      final searchType = r['search_type'] as String?;
      final result = r['result'];
      final sseEvents = r['sse_events'] as List<dynamic>?;
      final summary = r['summary'] as String?;

      List<Map<String, dynamic>> candidates = [];
      List<Map<String, dynamic>>? dinqResults;
      if (result is List) {
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
      final st = searchType == 'people_search'
          ? 'dinq'
          : (searchType ?? 'global');

      List<Map<String, dynamic>> thinkingSteps;
      if (sseEvents != null && sseEvents.isNotEmpty) {
        thinkingSteps = _convertSseEventsToThinkingSteps(sseEvents, groupId);
      } else if (summary != null && summary.trim().isNotEmpty) {
        thinkingSteps = [
          {
            'id': 'history-summary-$groupId',
            'type': 'thinking',
            'content': summary.trim(),
            'completed': true,
          },
        ];
      } else {
        thinkingSteps = [];
      }

      groups.add(
        AgenticMessageGroup(
          id: groupId,
          userQuery: query,
          loading: false,
          candidates: candidates,
          dinqResults: dinqResults,
          searchType: st,
          thinkingSteps: thinkingSteps,
          thinkingExpanded: false,
          searchCompleted: true,
        ),
      );
    }
    messageGroups = groups;
    loading = false;
    searchStore.loadConversation(conversation);
    notifyListeners();
  }

  /// 与 TSX clearMessages / startNewConversation 一致
  void clearMessages() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    searchStore.setCurrentConversationId(null);
    messageGroups = [];
    loading = false;
    advisorLoading = false;
    notifyListeners();
  }

  /// 与 TSX handleSearch 一致
  void handleSearch({required String query, bool simple = false}) {
    if (query.trim().isEmpty) return;

    searchStore.setIsSearching(true);
    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: query.trim(),
      loading: true,
      candidates: [],
      searchType: 'global',
      thinkingSteps: [],
      thinkingExpanded: false,
      searchCompleted: false,
    );

    messageGroups = [...messageGroups, group];
    loading = true;
    notifyListeners();

    final stream = searchService.chatStream(
      query: query.trim(),
      mode: simple ? 'fast' : 'research',
      conversationId: searchStore.currentConversationId,
    );

    _streamSubscription?.cancel();
    _streamSubscription = stream.listen(
      (event) {
        final type = event['type'] as String?;
        if (type == null) return;

        // 与 TSX processStreamEvent 一致的事件类型
        switch (type) {
          case 'started':
          case 'llm_start':
          case 'llm_end':
          case 'tool_call':
          case 'tool_result':
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
        if (idx >= 0) messageGroups[idx].loading = false;
        onSearchComplete?.call(finalCandidates, query.trim());
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

  /// 与 TSX handleAdvisorSearch 一致（占位，暂无 advisor 流式 API）
  void handleAdvisorSearch() {
    advisorLoading = true;
    notifyListeners();
    // TODO: 接入 advisor 流式 API
    Future.delayed(const Duration(milliseconds: 100), () {
      advisorLoading = false;
      notifyListeners();
      onScrollToBottom?.call();
    });
  }

  /// 与 TSX handleStop 一致
  void handleStop() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    searchStore.setIsSearching(false);
    loading = false;
    advisorLoading = false;
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
