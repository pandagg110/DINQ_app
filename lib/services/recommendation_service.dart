import 'package:dio/dio.dart';
import 'api_client.dart';
import '../constants/app_constants.dart';
import '../models/recommendation_models.dart';

/// 推荐论文 API 统一使用 baseUrl：$appUrl/api/recommendation
const String recommendationBaseUrl = '$appUrl/api/recommendation';

class RecommendationService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取推荐论文
  /// POST recommend_papers，参数与 TS RecommendPapersRequest 一致
  Future<List<RecommendedPaper>> recommendPapers({
    required String userId,
    int limit = 20,
    List<String>? conference,
    List<int>? year,
    List<String>? status,
    List<String>? group,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'limit': limit,
    };
    if (conference != null && conference.isNotEmpty) body['conference'] = conference;
    if (year != null && year.isNotEmpty) body['year'] = year;
    if (status != null && status.isNotEmpty) body['status'] = status;
    if (group != null && group.isNotEmpty) body['group'] = group;

    final response = await _dio.postUri(
      Uri.parse('$recommendationBaseUrl/recommend_papers'),
      data: body,
    );
    return _parsePaperList(response.data);
  }

  /// 相似论文检索
  /// POST match_papers，参数：paper_uid, match_count?
  Future<List<RecommendedPaper>> matchPapers({
    String? paperUid,
    int matchCount = 20,
  }) async {
    final body = <String, dynamic>{
      'paper_uid': paperUid,
      'match_count': matchCount,
    };
    final response = await _dio.postUri(
      Uri.parse('$recommendationBaseUrl/match_papers'),
      data: body,
    );
    return _parsePaperList(response.data);
  }

  /// 更新用户兴趣（点击论文时上报）
  /// POST update_interest，参数：user_id, paper_uid
  Future<void> updateInterest({
    required String userId,
    required String paperUid,
  }) async {
    await _dio.postUri(
      Uri.parse('$recommendationBaseUrl/update_interest'),
      data: {'user_id': userId, 'paper_uid': paperUid},
    );
  }

  static List<RecommendedPaper> _parsePaperList(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data
        .map((e) => RecommendedPaper.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
