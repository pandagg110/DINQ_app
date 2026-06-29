import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/card_models.dart';
import 'api_client.dart';

class CardService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取 Card Board
  Future<List<CardItem>> getCardBoard(String username) async {
    debugPrint('[CardAPI] GET /card-board username=$username -> start');
    final response = await _dio.get(
      '/card-board',
      queryParameters: {'username': username},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final list = data['board'] as List<dynamic>? ?? [];
    final cards = list
        .map(
          (item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    debugPrint(
      '[CardAPI] GET /card-board username=$username <- ${cards.length} cards '
      '${cards.map((c) => '${c.id}:${c.data.id}:${c.data.type}:${c.data.status}').join(', ')}',
    );
    return cards;
  }

  /// 更新 Card Board（与 TS cardApi.updateCardBoard 一致：仅提交 dirty 卡片，AI 卡 type 转为 datasource）
  /// 服务端可能返回空或无 board 字段，需空安全解析避免 type 'Null' is not a subtype of type 'Map'
  Future<List<CardItem>> updateCardBoard(List<CardItem> board) async {
    debugPrint(
      '[CardAPI] POST /card-board -> ${board.length} dirty cards '
      '${board.map((c) => '${c.id}:${c.data.id}:${c.data.type}:${c.data.status}').join(', ')}',
    );
    final response = await _dio.post(
      '/card-board',
      data: {'board': board.map((card) => card.toJson()).toList()},
    );
    final raw = response.data;
    if (raw == null) return [];
    final data = Map<String, dynamic>.from(raw as Map);
    final list = data['board'] as List<dynamic>? ?? [];
    final result = <CardItem>[];
    for (final item in list) {
      if (item == null) continue;
      try {
        result.add(CardItem.fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (_) {
        // 单条解析失败时跳过，不因一条坏数据导致整次保存报错
      }
    }
    return result;
  }

  /// 删除数据源
  Future<void> deleteCard(String id) async {
    await _dio.get('/card-board/delete/$id');
  }

  /// 初始化 Card Board
  Future<List<CardItem>> initCardBoard(Map<String, dynamic> data) async {
    final response = await _dio.post('/card-board/init', data: data);
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final list = responseData['board'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// 添加卡片到 Board
  /// [type] 卡片类型
  /// [title] 标题（可选）
  /// [content] 内容（可选）
  /// [description] 描述（可选）
  /// [metadata] 元数据（可选）
  Future<CardItem> addCardToBoard({
    required String type,
    String? title,
    String? content,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint(
      '[CardAPI] POST /card-board/add -> type=$type metadata=$metadata',
    );
    final response = await _dio.post(
      '/card-board/add',
      data: {
        'type': type,
        'data': {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (description != null) 'description': description,
          if (metadata != null) 'metadata': metadata,
        },
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final card = CardItem.fromJson(
      Map<String, dynamic>.from(data['board'] as Map),
    );
    debugPrint(
      '[CardAPI] POST /card-board/add <- card=${card.id} datasource=${card.data.id} '
      'type=${card.data.type} status=${card.data.status} metadata=${card.data.metadata}',
    );
    return card;
  }

  /// 获取所有卡片
  Future<List<CardItem>> getAllCards(Map<String, dynamic> data) async {
    final response = await _dio.post('/tool/all/cards', data: data);
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final list = responseData['board'] as List<dynamic>? ?? [];
    return list
        .map(
          (item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// 校验社交链接 URL（对齐 Web cardApi.validateUrl）
  Future<Map<String, dynamic>> validateUrl({required String url}) async {
    debugPrint('[CardAPI] POST /card/validate-url -> url=$url');
    final response = await _dio.post('/card/validate-url', data: {'url': url});
    final data = Map<String, dynamic>.from(response.data as Map);
    debugPrint('[CardAPI] POST /card/validate-url <- $data');
    return data;
  }

  /// 生成 Card
  /// [datasourceId] 数据源 ID
  /// [type] 卡片类型
  /// [url] URL（可选）
  /// [extraMetadata] 额外的元数据（可选）
  Future<Map<String, dynamic>> generateCard({
    required String datasourceId,
    required String type,
    String? url,
    Map<String, dynamic>? extraMetadata,
  }) async {
    final data = {
      'datasource_id': datasourceId,
      'type': type,
      if (url != null) 'url': url,
      if (extraMetadata != null) ...extraMetadata,
    };
    debugPrint('[CardAPI] POST /card/generate -> $data');
    final response = await _dio.post('/card/generate', data: data);
    final result = Map<String, dynamic>.from(response.data as Map);
    debugPrint('[CardAPI] POST /card/generate <- $result');
    return result;
  }
}
