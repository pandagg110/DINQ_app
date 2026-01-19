import 'package:dio/dio.dart';
import '../models/card_models.dart';
import 'api_client.dart';

class CardService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CardItem>> getCardBoard(String username) async {
    final response = await _dio.get('/card-board', queryParameters: {'username': username});
    final data = Map<String, dynamic>.from(response.data as Map);
    final list = data['board'] as List<dynamic>? ?? [];
    return list.map((item) => CardItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> updateCardBoard(List<CardItem> board) async {
    await _dio.post('/card-board', data: {
      'board': board.map((card) => card.toJson()).toList(),
    });
  }

  Future<CardItem> addCardToBoard({required String type, Map<String, dynamic>? metadata}) async {
    final response = await _dio.post('/card-board/add', data: {
      'type': type,
      'data': {'metadata': metadata ?? {}}
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return CardItem.fromJson(Map<String, dynamic>.from(data['board'] as Map));
  }

  Future<void> deleteCard(String id) async {
    await _dio.get('/card-board/delete/$id');
  }

  Future<void> generateCard({required String type, required String datasourceId}) async {
    await _dio.post('/card/generate', data: {
      'type': type,
      'datasource_id': datasourceId,
    });
  }
}


