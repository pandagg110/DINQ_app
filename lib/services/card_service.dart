import 'package:dio/dio.dart';
import '../models/card_models.dart';
import 'api_client.dart';

class CardService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取 Card Board
  Future<List<CardItem>> getCardBoard(String username) async {
    final response = await _dio.get(
      '/card-board',
      queryParameters: {'username': username},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final list = data['board'] as List<dynamic>? ?? [];
    return list.map((item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  /// 更新 Card Board
  Future<List<CardItem>> updateCardBoard(List<CardItem> board) async {
    final response = await _dio.post('/card-board', data: {
      'board': board.map((card) => card.toJson()).toList(),
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    final list = data['board'] as List<dynamic>? ?? [];
    return list.map((item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
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
    return list.map((item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
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
    final response = await _dio.post('/card-board/add', data: {
      'type': type,
      'data': {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': metadata,
      },
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return CardItem.fromJson(Map<String, dynamic>.from(data['board'] as Map));
  }

  /// 获取所有卡片
  Future<List<CardItem>> getAllCards(Map<String, dynamic> data) async {
    final response = await _dio.post('/tool/all/cards', data: data);
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final list = responseData['board'] as List<dynamic>? ?? [];
    return list.map((item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
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
    final response = await _dio.post('/card/generate', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}


