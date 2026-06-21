import 'dart:async';

import '../../../utils/parse_quick_replies.dart';
import 'deep_search_models.dart';

const _thinkingDeltaFlushMs = 100;
const _thinkingTextMaxChars = 12000;

/// 与 TSX `dispatchStreamEvent` 对齐，就地更新 message group 的 subAgents / 状态。
class DeepSearchEventDispatcher {
  DeepSearchEventDispatcher({
    required this.subAgents,
    required this.contentBlocks,
    required this.onCandidatesChanged,
    this.onSessionId,
    this.onSseEventsId,
    this.onDurationMs,
    this.onError,
    this.onStatusChange,
  });

  Map<String, SubAgentInfo> subAgents;
  List<MessagePart> contentBlocks;
  final void Function(List<Map<String, dynamic>> candidates) onCandidatesChanged;
  final void Function(String sessionId)? onSessionId;
  final void Function(String sseEventsId)? onSseEventsId;
  final void Function(int durationMs)? onDurationMs;
  final void Function(String message)? onError;
  final void Function(DeepSearchRoundStatus status)? onStatusChange;

  List<Map<String, dynamic>> _candidates = [];
  final Map<String, Map<String, dynamic>> _candidateRows = {};
  final List<String> _candidateOrder = [];

  String _rowKey(Map<String, dynamic> row) {
    final rowId = row['row_id']?.toString();
    if (rowId != null && rowId.isNotEmpty) return rowId;
    return 'anon:${row['name']}|${row['company']}|${row['title']}';
  }

  List<Map<String, dynamic>> _rowsSnapshot() {
    return _candidateOrder
        .map((key) => Map<String, dynamic>.from(_candidateRows[key]!))
        .toList();
  }

  void _emitCandidates() {
    _candidates = _rowsSnapshot();
    onCandidatesChanged(_candidates);
  }

  void _upsertCandidate(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final key = _rowKey(map);
    if (!_candidateRows.containsKey(key)) {
      _candidateOrder.add(key);
    }
    _candidateRows[key] = map;
    _emitCandidates();
  }

  void setCandidates(List<Map<String, dynamic>> candidates) {
    _candidateRows.clear();
    _candidateOrder.clear();
    for (final row in candidates) {
      final map = Map<String, dynamic>.from(row);
      final key = _rowKey(map);
      if (!_candidateRows.containsKey(key)) {
        _candidateOrder.add(key);
      }
      _candidateRows[key] = map;
    }
    _candidates = _rowsSnapshot();
  }

  List<Map<String, dynamic>> get candidates => _candidates;

  String _pendingThinkingDelta = '';
  Timer? _pendingThinkingTimer;

  String _trimThinkingText(String text) {
    if (text.length <= _thinkingTextMaxChars) return text;
    return text.substring(text.length - _thinkingTextMaxChars);
  }

  void _syncVirtualAgentCandidateCount() {
    final va = subAgents[virtualAgentId];
    if (va == null) return;
    subAgents[virtualAgentId] =
        va.copyWith(candidatesFound: _candidates.length);
  }

  void _flushPendingThinkingDelta() {
    _pendingThinkingTimer?.cancel();
    _pendingThinkingTimer = null;
    if (_pendingThinkingDelta.isEmpty) return;
    final content = _pendingThinkingDelta;
    _pendingThinkingDelta = '';
    _applyThinkingDelta(content);
  }

  void _enqueueThinkingDelta(String content) {
    if (content.isEmpty) return;
    _pendingThinkingDelta += content;
    _pendingThinkingTimer ??= Timer(
      const Duration(milliseconds: _thinkingDeltaFlushMs),
      _flushPendingThinkingDelta,
    );
  }

  void disposeThinkingTimer() {
    _pendingThinkingTimer?.cancel();
    _pendingThinkingTimer = null;
    _pendingThinkingDelta = '';
  }

  void dispatch(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == null) return;

    switch (type) {
      case 'session':
        _handleSession(event);
      case 'session_meta':
        _handleSessionMeta(event);
      case 'status':
        _handleStatus(event);
      case 'tool_use':
        _handleToolUse(event);
      case 'tool_result':
        _handleToolResult(event);
      case 'system':
        onStatusChange?.call(DeepSearchRoundStatus.searching);
      case 'text_delta':
        _handleTextDelta(event);
      case 'text':
        _handleText(event);
      case 'tool_message':
        _handleToolMessage(event);
      case 'subagent_start':
        _handleSubagentStart(event);
      case 'subagent_event':
        _handleSubagentEvent(event);
      case 'subagent_end':
        _handleSubagentEnd(event);
      case 'done':
        _handleDone(event);
      case 'error':
        _handleError(event);
      case 'interrupted':
        _handleInterrupted(event);
      case 'thinking_delta':
        _handleThinkingDelta(event);
      case 'thinking':
        _handleThinkingEnd();
    }
  }

  void _handleSession(Map<String, dynamic> event) {
    final sessionId = event['session_id']?.toString();
    if (sessionId != null && sessionId.isNotEmpty) {
      onSessionId?.call(sessionId);
    }
    final sseEventsId = event['sse_events_id']?.toString();
    if (sseEventsId != null && sseEventsId.isNotEmpty) {
      onSseEventsId?.call(sseEventsId);
    }
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleSessionMeta(Map<String, dynamic> event) {
    final sessionId = event['session_id']?.toString();
    if (sessionId != null && sessionId.isNotEmpty) {
      onSessionId?.call(sessionId);
    }
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleStatus(Map<String, dynamic> event) {
    contentBlocks = [
      ...contentBlocks,
      StatusPart(
        StatusBlock(
          id: nextBlockId('status'),
          message: event['message']?.toString() ?? '',
        ),
      ),
    ];
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleToolUse(Map<String, dynamic> event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final toolUseId =
        event['tool_use_id']?.toString() ?? nextBlockId('tool-use');
    final name = event['name']?.toString() ?? event['tool_name']?.toString() ?? 'Tool';
    final input = event['input'] ?? event['data'];

    if (!hasRealSubAgents(subAgents)) {
      final created = getOrCreateVirtualAgent(subAgents);
      subAgents = created.agents;
      final agent = created.agent;
      final closed = closeActiveBlock(closeOpenThinkingBlocks(agent.contentBlocks));
      subAgents[virtualAgentId] = agent.copyWith(
        contentBlocks: [
          ...closed,
          ToolCallPart(
            ToolCallBlock(
              id: toolUseId,
              name: name,
              input: input,
              startedAt: now,
            ),
          ),
        ],
      );
    } else {
      contentBlocks = closeActiveBlock(contentBlocks);
      final existingIdx = contentBlocks.indexWhere(
        (b) => b is ToolCallPart && b.block.id == toolUseId,
      );
      if (existingIdx >= 0) {
        final part = contentBlocks[existingIdx] as ToolCallPart;
        contentBlocks = [
          ...contentBlocks.sublist(0, existingIdx),
          ToolCallPart(
            part.block.copyWith(
              name: name,
              input: input,
              status: ToolCallStatus.running,
            ),
          ),
          ...contentBlocks.sublist(existingIdx + 1),
        ];
      } else {
        contentBlocks = [
          ...contentBlocks,
          ToolCallPart(
            ToolCallBlock(
              id: toolUseId,
              name: name,
              input: input,
              startedAt: now,
            ),
          ),
        ];
      }
    }
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleToolResult(Map<String, dynamic> event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final toolUseId = event['tool_use_id']?.toString();
    if (toolUseId == null) return;
    final content = event['content']?.toString() ?? '';

    if (!hasRealSubAgents(subAgents)) {
      final created = getOrCreateVirtualAgent(subAgents);
      subAgents = created.agents;
      final agent = created.agent;
      subAgents[virtualAgentId] = agent.copyWith(
        contentBlocks: agent.contentBlocks.map((part) {
          if (part is ToolCallPart && part.block.id == toolUseId) {
            return ToolCallPart(
              part.block.copyWith(
                status: ToolCallStatus.done,
                result: content,
                endedAt: now,
              ),
            );
          }
          return part;
        }).toList(),
      );
    } else {
      final existingIdx = contentBlocks.indexWhere(
        (b) => b is ToolCallPart && b.block.id == toolUseId,
      );
      if (existingIdx == -1) {
        contentBlocks = [
          ...contentBlocks,
          ToolCallPart(
            ToolCallBlock(
              id: toolUseId,
              name: 'Tool',
              input: null,
              status: ToolCallStatus.done,
              result: content,
              startedAt: now,
              endedAt: now,
            ),
          ),
        ];
      } else {
        contentBlocks = contentBlocks.map((part) {
          if (part is ToolCallPart && part.block.id == toolUseId) {
            return ToolCallPart(
              part.block.copyWith(
                status: ToolCallStatus.done,
                result: content,
                endedAt: now,
              ),
            );
          }
          return part;
        }).toList();
      }
    }
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _appendReasoningToAgent(String agentId, String content) {
    final agent = subAgents[agentId];
    if (agent == null) return;
    final blocks = [...closeOpenThinkingBlocks(agent.contentBlocks)];
    if (blocks.isNotEmpty && blocks.last is ReasoningPart) {
      final last = blocks.last as ReasoningPart;
      if (last.block.isStreaming) {
        blocks[blocks.length - 1] = ReasoningPart(
          last.block.copyWith(text: last.block.text + content),
        );
      } else {
        blocks.add(
          ReasoningPart(
            ReasoningBlock(
              id: nextBlockId('sa-reasoning'),
              text: content,
              isStreaming: true,
            ),
          ),
        );
      }
    } else {
      blocks.add(
        ReasoningPart(
          ReasoningBlock(
            id: nextBlockId('sa-reasoning'),
            text: content,
            isStreaming: true,
          ),
        ),
      );
    }
    subAgents[agentId] = agent.copyWith(
      streamingText: agent.streamingText + content,
      contentBlocks: blocks,
    );
  }

  void _handleTextDelta(Map<String, dynamic> event) {
    final content = normalizeAssistantTextContent(event['content']);
    if (content.isEmpty) return;

    if (!hasRealSubAgents(subAgents)) {
      final created = getOrCreateVirtualAgent(subAgents);
      subAgents = created.agents;
      _appendReasoningToAgent(virtualAgentId, content);
    } else {
      if (contentBlocks.isNotEmpty && contentBlocks.last is ReasoningPart) {
        final last = contentBlocks.last as ReasoningPart;
        if (last.block.isStreaming) {
          contentBlocks = [
            ...contentBlocks.sublist(0, contentBlocks.length - 1),
            ReasoningPart(last.block.copyWith(text: last.block.text + content)),
          ];
        } else {
          contentBlocks = [
            ...contentBlocks,
            ReasoningPart(
              ReasoningBlock(
                id: nextBlockId('reasoning'),
                text: content,
                isStreaming: true,
              ),
            ),
          ];
        }
      } else {
        contentBlocks = [
          ...contentBlocks,
          ReasoningPart(
            ReasoningBlock(
              id: nextBlockId('reasoning'),
              text: content,
              isStreaming: true,
            ),
          ),
        ];
      }
    }
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleText(Map<String, dynamic> event) {
    if (hasRealSubAgents(subAgents)) return;
    _flushPendingThinkingDelta();
    final content = normalizeAssistantTextContent(event['content']);
    if (content.isNotEmpty) {
      _handleTextDelta({'content': content});
    }
    _closeVirtualAgentOpenThinking();
  }

  void _closeVirtualAgentOpenThinking() {
    final va = subAgents[virtualAgentId];
    if (va == null) return;
    final closed = closeActiveBlock(closeOpenThinkingBlocks(va.contentBlocks));
    if (identical(closed, va.contentBlocks)) return;
    subAgents[virtualAgentId] = va.copyWith(contentBlocks: closed);
  }

  void _handleToolMessage(Map<String, dynamic> event) {
    final data = event['data'];
    if (data is! Map) return;
    final action = data['action']?.toString();
    if (action == 'add_row') {
      final row = data['row'];
      if (row is Map) {
        _upsertCandidate(Map<String, dynamic>.from(row));
      }
    } else if (action == 'delete_row') {
      final rowId = data['row_id']?.toString();
      if (rowId != null) {
        _candidateRows.remove(rowId);
        _candidateOrder.remove(rowId);
        _emitCandidates();
      }
    } else if (action == 'update_row') {
      final rowId = data['row_id']?.toString();
      final patch = data['patch'];
      if (rowId != null && patch is Map) {
        final existing = _candidateRows[rowId];
        if (existing != null) {
          _candidateRows[rowId] = {
            ...existing,
            ...Map<String, dynamic>.from(patch),
          };
          _emitCandidates();
        }
      }
    }
    _syncVirtualAgentCandidateCount();
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleSubagentStart(Map<String, dynamic> event) {
    final id = event['subagent_id']?.toString();
    if (id == null) return;
    subAgents = {
      ...subAgents,
      id: SubAgentInfo(
        id: id,
        name: event['subagent_name']?.toString() ?? id,
        description: event['description']?.toString() ?? '',
        status: DeepSearchRoundStatus.searching,
      ),
    };
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _handleSubagentEvent(Map<String, dynamic> event) {
    final agentId = event['subagent_id']?.toString();
    final inner = event['event'];
    if (agentId == null || inner is! Map) return;
    final innerEvent = Map<String, dynamic>.from(inner);
    final innerType = innerEvent['type']?.toString();

    if (innerType == 'tool_message') {
      dispatch(innerEvent);
      return;
    }

    final agent = subAgents[agentId];
    if (agent == null) return;

    if (innerType == 'text_delta' || innerType == 'text') {
      final content = normalizeAssistantTextContent(innerEvent['content']);
      if (content.isNotEmpty) {
        subAgents = {...subAgents};
        _appendReasoningToAgent(agentId, content);
      }
      return;
    }

    if (innerType == 'tool_use') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final closed = closeActiveBlock(agent.contentBlocks);
      subAgents[agentId] = agent.copyWith(
        contentBlocks: [
          ...closed,
          ToolCallPart(
            ToolCallBlock(
              id: innerEvent['tool_use_id']?.toString() ?? nextBlockId('tool'),
              name: innerEvent['name']?.toString() ?? 'Tool',
              input: innerEvent['input'],
              startedAt: now,
            ),
          ),
        ],
      );
      return;
    }

    if (innerType == 'tool_result') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final toolUseId = innerEvent['tool_use_id']?.toString();
      if (toolUseId == null) return;
      subAgents[agentId] = agent.copyWith(
        contentBlocks: agent.contentBlocks.map((part) {
          if (part is ToolCallPart && part.block.id == toolUseId) {
            return ToolCallPart(
              part.block.copyWith(
                status: ToolCallStatus.done,
                result: innerEvent['content']?.toString(),
                endedAt: now,
              ),
            );
          }
          return part;
        }).toList(),
      );
      return;
    }

    if (innerType == 'status') {
      subAgents[agentId] = agent.copyWith(
        contentBlocks: [
          ...agent.contentBlocks,
          StatusPart(
            StatusBlock(
              id: nextBlockId('sa-status'),
              message: innerEvent['message']?.toString() ?? '',
            ),
          ),
        ],
      );
    }
  }

  void _handleSubagentEnd(Map<String, dynamic> event) {
    final id = event['subagent_id']?.toString();
    if (id == null) return;
    final existing = subAgents[id];
    final closedBlocks =
        existing != null ? closeActiveBlock(existing.contentBlocks) : <MessagePart>[];
    subAgents = {
      ...subAgents,
      id: (existing ??
              SubAgentInfo(
                id: id,
                name: event['subagent_name']?.toString() ?? id,
              ))
          .copyWith(
        status: DeepSearchRoundStatus.done,
        candidatesFound: event['candidates_found'] is int
            ? event['candidates_found'] as int
            : int.tryParse(event['candidates_found']?.toString() ?? '') ?? 0,
        durationS: event['duration_s'] is num
            ? (event['duration_s'] as num).toDouble()
            : double.tryParse(event['duration_s']?.toString() ?? ''),
        contentBlocks: closedBlocks,
      ),
    };
    onStatusChange?.call(DeepSearchRoundStatus.searching);
  }

  void _closeVirtualAgent(double? durationS) {
    final va = subAgents[virtualAgentId];
    if (va == null) return;
    subAgents[virtualAgentId] = va.copyWith(
      status: DeepSearchRoundStatus.done,
      candidatesFound: _candidates.length,
      durationS: durationS,
      contentBlocks: closeActiveBlock(closeOpenThinkingBlocks(va.contentBlocks)),
    );
  }

  void _closeVirtualAgentWithError() {
    final va = subAgents[virtualAgentId];
    if (va == null || va.status == DeepSearchRoundStatus.done) return;
    subAgents[virtualAgentId] = va.copyWith(
      status: DeepSearchRoundStatus.error,
      contentBlocks: markRunningToolsAsError(
        closeActiveBlock(closeOpenThinkingBlocks(va.contentBlocks)),
      ),
    );
  }

  void _handleDone(Map<String, dynamic> event) {
    _flushPendingThinkingDelta();
    final durationMs = event['duration_ms'];
    int? ms;
    if (durationMs is int) {
      ms = durationMs;
    } else if (durationMs != null) {
      ms = int.tryParse(durationMs.toString());
    }
    if (ms != null) onDurationMs?.call(ms);

    final sessionId = event['session_id']?.toString();
    if (sessionId != null && sessionId.isNotEmpty) {
      onSessionId?.call(sessionId);
    }

    contentBlocks = closeActiveBlock(contentBlocks);
    _closeVirtualAgent(ms != null ? ms / 1000 : null);
    onStatusChange?.call(DeepSearchRoundStatus.done);
  }

  void _handleError(Map<String, dynamic> event) {
    final message = event['message']?.toString() ?? 'Search failed';
    contentBlocks =
        markRunningToolsAsError(closeActiveBlock(contentBlocks));
    _closeVirtualAgentWithError();
    onError?.call(message);
    onStatusChange?.call(DeepSearchRoundStatus.error);
  }

  void _handleInterrupted(Map<String, dynamic> event) {
    final reason = event['reason']?.toString() ?? 'Interrupted';
    contentBlocks =
        markRunningToolsAsError(closeActiveBlock(contentBlocks));
    _closeVirtualAgentWithError();
    onError?.call(reason);
    onStatusChange?.call(DeepSearchRoundStatus.interrupted);
  }

  void _handleThinkingDelta(Map<String, dynamic> event) {
    if (hasRealSubAgents(subAgents)) return;
    final content = event['content']?.toString() ?? '';
    _enqueueThinkingDelta(content);
  }

  void _applyThinkingDelta(String content) {
    if (content.isEmpty) return;

    final created = getOrCreateVirtualAgent(subAgents);
    subAgents = created.agents;
    final agent = created.agent;
    final blocks = [...agent.contentBlocks];
    final now = DateTime.now().millisecondsSinceEpoch;

    if (blocks.isNotEmpty && blocks.last is ThinkingPart) {
      final last = blocks.last as ThinkingPart;
      if (last.block.isStreaming) {
        blocks[blocks.length - 1] = ThinkingPart(
          last.block.copyWith(
            text: _trimThinkingText(last.block.text + content),
          ),
        );
      } else {
        blocks.add(
          ThinkingPart(
            ThinkingBlock(
              id: nextBlockId('sa-thinking'),
              text: _trimThinkingText(content),
              isStreaming: true,
              startedAt: now,
            ),
          ),
        );
      }
    } else {
      blocks.add(
        ThinkingPart(
          ThinkingBlock(
            id: nextBlockId('sa-thinking'),
            text: _trimThinkingText(content),
            isStreaming: true,
            startedAt: now,
          ),
        ),
      );
    }
    subAgents[virtualAgentId] = agent.copyWith(contentBlocks: blocks);
  }

  void _handleThinkingEnd() {
    _flushPendingThinkingDelta();
    if (hasRealSubAgents(subAgents)) return;
    final va = subAgents[virtualAgentId];
    if (va == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    subAgents[virtualAgentId] = va.copyWith(
      contentBlocks: va.contentBlocks.map((part) {
        if (part is ThinkingPart && part.block.isStreaming) {
          return ThinkingPart(
            part.block.copyWith(isStreaming: false, endedAt: now),
          );
        }
        return part;
      }).toList(),
    );
  }

  /// 历史回放：将 `text` 事件合成为 text_delta + close，与 restoreDiscover 一致。
  void dispatchHistoryEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == 'session' || type == 'session_meta') return;

    if (type == 'text') {
      final content = normalizeAssistantTextContent(event['content']);
      if (content.isNotEmpty) {
        dispatch({'type': 'text_delta', 'content': content});
      }
      final va = subAgents[virtualAgentId];
      if (va != null) {
        subAgents[virtualAgentId] = va.copyWith(
          contentBlocks: closeActiveBlock(closeOpenThinkingBlocks(va.contentBlocks)),
        );
      }
      return;
    }

    dispatch(event);
  }

  void finalizeHistoryReplay() {
    _flushPendingThinkingDelta();
    _closeVirtualAgent(
      subAgents[virtualAgentId]?.durationS != null
          ? subAgents[virtualAgentId]!.durationS
          : null,
    );
  }
}
