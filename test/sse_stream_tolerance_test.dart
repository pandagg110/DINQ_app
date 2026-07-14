import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dinq_app/services/api_client.dart';
import 'package:dinq_app/services/discover_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 把 SSE 文本编码成 UTF-8 字节后，故意在多字节字符中间切分成多个 chunk，
/// 复现真实网络分片。修复前 `utf8.decode(chunk)` 会抛 FormatException。
class SplitChunkAdapter implements HttpClientAdapter {
  SplitChunkAdapter(this.chunks);

  final List<List<int>> chunks;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      Stream.fromIterable(chunks.map(Uint8List.fromList)),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('SSE 流式解码：多字节字符被 chunk 边界截断不抛 FormatException',
      () async {
    const sse = 'data: {"type":"text_delta","content":"你好世界"}\n'
        'data: {"type":"done","duration_ms":10}\n';
    final bytes = utf8.encode(sse);
    // "你" 的 3 个字节从偏移 39 开始；40 处切断 = 字符被劈开
    final chunks = [
      bytes.sublist(0, 40),
      bytes.sublist(40, 41),
      bytes.sublist(41),
    ];
    ApiClient.instance.dio.httpClientAdapter = SplitChunkAdapter(chunks);

    final events = await SearchService().chatStream(query: 'x').toList();
    expect(events.length, 2);
    expect(events[0]['type'], 'text_delta');
    expect(events[0]['content'], '你好世界');
    expect(events[1]['type'], 'done');
  });

  test('SSE 单条畸形事件被跳过，不中断后续事件', () async {
    const sse = 'data: {"type":"text_delta","content":"ok"}\n'
        'data: {"type":"broken"\n' // JSON 缺右括号 → 跳过该条
        'data: {"type":"done"}\n';
    final bytes = utf8.encode(sse);
    ApiClient.instance.dio.httpClientAdapter = SplitChunkAdapter([bytes]);

    final events = await SearchService().chatStream(query: 'x').toList();
    expect(events.length, 2);
    expect(events[0]['type'], 'text_delta');
    expect(events[1]['type'], 'done');
  });
}
