// Deep Search 数据模型，与 TSX `@/store/deep-search/types` 对齐。

const virtualAgentId = '__single__';

int _blockIdCounter = 0;
String nextBlockId(String prefix) {
  _blockIdCounter += 1;
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_blockIdCounter';
}

enum DeepSearchRoundStatus { idle, searching, done, error, interrupted }

enum ToolCallStatus { running, done, error }

class ReasoningBlock {
  ReasoningBlock({
    required this.id,
    required this.text,
    this.isStreaming = false,
  });

  final String id;
  final String text;
  final bool isStreaming;

  ReasoningBlock copyWith({String? text, bool? isStreaming}) => ReasoningBlock(
        id: id,
        text: text ?? this.text,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  Map<String, dynamic> toJson() => {
        'type': 'reasoning',
        'id': id,
        'text': text,
        'isStreaming': isStreaming,
      };

  static ReasoningBlock? fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'reasoning') return null;
    return ReasoningBlock(
      id: json['id']?.toString() ?? nextBlockId('reasoning'),
      text: json['text']?.toString() ?? '',
      isStreaming: json['isStreaming'] == true,
    );
  }
}

class ThinkingBlock {
  ThinkingBlock({
    required this.id,
    required this.text,
    this.isStreaming = false,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String text;
  final bool isStreaming;
  final int startedAt;
  final int? endedAt;

  ThinkingBlock copyWith({
    String? text,
    bool? isStreaming,
    int? endedAt,
  }) =>
      ThinkingBlock(
        id: id,
        text: text ?? this.text,
        isStreaming: isStreaming ?? this.isStreaming,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  Map<String, dynamic> toJson() => {
        'type': 'thinking',
        'id': id,
        'text': text,
        'isStreaming': isStreaming,
        'startedAt': startedAt,
        if (endedAt != null) 'endedAt': endedAt,
      };
}

class ToolCallBlock {
  ToolCallBlock({
    required this.id,
    required this.name,
    required this.input,
    this.status = ToolCallStatus.running,
    this.result,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String name;
  final dynamic input;
  final ToolCallStatus status;
  final String? result;
  final int startedAt;
  final int? endedAt;

  ToolCallBlock copyWith({
    String? name,
    dynamic input,
    ToolCallStatus? status,
    String? result,
    int? endedAt,
  }) =>
      ToolCallBlock(
        id: id,
        name: name ?? this.name,
        input: input ?? this.input,
        status: status ?? this.status,
        result: result ?? this.result,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  Map<String, dynamic> toJson() => {
        'type': 'tool_call',
        'id': id,
        'name': name,
        'input': input,
        'status': status.name,
        'result': result,
        'startedAt': startedAt,
        if (endedAt != null) 'endedAt': endedAt,
      };
}

class StatusBlock {
  StatusBlock({required this.id, required this.message});

  final String id;
  final String message;
}

sealed class MessagePart {}

class ReasoningPart extends MessagePart {
  ReasoningPart(this.block);
  final ReasoningBlock block;
}

class ThinkingPart extends MessagePart {
  ThinkingPart(this.block);
  final ThinkingBlock block;
}

class ToolCallPart extends MessagePart {
  ToolCallPart(this.block);
  final ToolCallBlock block;
}

class StatusPart extends MessagePart {
  StatusPart(this.block);
  final StatusBlock block;
}

MessagePart? messagePartFromDynamic(dynamic value) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  switch (map['type']) {
    case 'reasoning':
      final block = ReasoningBlock.fromJson(map);
      return block == null ? null : ReasoningPart(block);
    case 'thinking':
      return ThinkingPart(
        ThinkingBlock(
          id: map['id']?.toString() ?? nextBlockId('thinking'),
          text: map['text']?.toString() ?? '',
          isStreaming: map['isStreaming'] == true,
          startedAt: map['startedAt'] is int
              ? map['startedAt'] as int
              : DateTime.now().millisecondsSinceEpoch,
          endedAt: map['endedAt'] as int?,
        ),
      );
    case 'tool_call':
      return ToolCallPart(
        ToolCallBlock(
          id: map['id']?.toString() ?? nextBlockId('tool'),
          name: map['name']?.toString() ?? 'Tool',
          input: map['input'],
          status: _toolStatusFrom(map['status']),
          result: map['result']?.toString(),
          startedAt: map['startedAt'] is int
              ? map['startedAt'] as int
              : DateTime.now().millisecondsSinceEpoch,
          endedAt: map['endedAt'] as int?,
        ),
      );
    case 'status':
      return StatusPart(
        StatusBlock(
          id: map['id']?.toString() ?? nextBlockId('status'),
          message: map['message']?.toString() ?? '',
        ),
      );
    default:
      return null;
  }
}

ToolCallStatus _toolStatusFrom(dynamic value) {
  final s = value?.toString();
  if (s == 'done') return ToolCallStatus.done;
  if (s == 'error') return ToolCallStatus.error;
  return ToolCallStatus.running;
}

List<MessagePart> cloneMessageParts(List<MessagePart> blocks) =>
    List<MessagePart>.from(blocks);

List<MessagePart> closeActiveBlock(List<MessagePart> blocks) {
  if (blocks.isEmpty) return blocks;
  final last = blocks.last;
  if (last is ReasoningPart && last.block.isStreaming) {
    return [
      ...blocks.sublist(0, blocks.length - 1),
      ReasoningPart(last.block.copyWith(isStreaming: false)),
    ];
  }
  return blocks;
}

List<MessagePart> markRunningToolsAsError(List<MessagePart> blocks) {
  var changed = false;
  final mapped = blocks.map((part) {
    if (part is ToolCallPart && part.block.status == ToolCallStatus.running) {
      changed = true;
      return ToolCallPart(
        part.block.copyWith(
          status: ToolCallStatus.error,
          endedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    return part;
  }).toList();
  return changed ? mapped : blocks;
}

List<MessagePart> closeOpenThinkingBlocks(List<MessagePart> blocks) {
  final now = DateTime.now().millisecondsSinceEpoch;
  var changed = false;
  final mapped = blocks.map((part) {
    if (part is ThinkingPart && part.block.isStreaming) {
      changed = true;
      return ThinkingPart(
        part.block.copyWith(isStreaming: false, endedAt: now),
      );
    }
    return part;
  }).toList();
  return changed ? mapped : blocks;
}

class SubAgentInfo {
  SubAgentInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.status = DeepSearchRoundStatus.searching,
    this.candidatesFound = 0,
    this.durationS,
    this.streamingText = '',
    List<MessagePart>? contentBlocks,
  }) : contentBlocks = contentBlocks ?? [];

  final String id;
  final String name;
  final String description;
  DeepSearchRoundStatus status;
  int candidatesFound;
  double? durationS;
  String streamingText;
  List<MessagePart> contentBlocks;

  SubAgentInfo copyWith({
    String? name,
    String? description,
    DeepSearchRoundStatus? status,
    int? candidatesFound,
    double? durationS,
    String? streamingText,
    List<MessagePart>? contentBlocks,
  }) =>
      SubAgentInfo(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        status: status ?? this.status,
        candidatesFound: candidatesFound ?? this.candidatesFound,
        durationS: durationS ?? this.durationS,
        streamingText: streamingText ?? this.streamingText,
        contentBlocks: contentBlocks ?? this.contentBlocks,
      );
}

bool hasRealSubAgents(Map<String, SubAgentInfo> subAgents) =>
    subAgents.keys.any((id) => id != virtualAgentId);

({Map<String, SubAgentInfo> agents, SubAgentInfo agent}) getOrCreateVirtualAgent(
  Map<String, SubAgentInfo> subAgents,
) {
  final existing = subAgents[virtualAgentId];
  if (existing != null) return (agents: subAgents, agent: existing);
  final agent = SubAgentInfo(
    id: virtualAgentId,
    name: 'deep-search',
    status: DeepSearchRoundStatus.searching,
  );
  return (
    agents: {...subAgents, virtualAgentId: agent},
    agent: agent,
  );
}

SubAgentInfo updateVirtualAgentBlocks(
  SubAgentInfo agent,
  List<MessagePart> blocks, {
  String? streamingText,
}) =>
    agent.copyWith(
      contentBlocks: blocks,
      streamingText: streamingText ?? agent.streamingText,
    );
