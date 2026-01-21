import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class FlowService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取用户流程状态
  Future<UserFlow> getFlow() async {
    final response = await _dio.get('/flow');
    return UserFlow.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 检查域名可用性
  Future<Map<String, dynamic>> checkDomain({required String domain}) async {
    final response = await _dio.post('/flow/check-domain', data: {'domain': domain});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 占用域名
  Future<UserFlow> claimDomain({required String domain}) async {
    final response = await _dio.post('/flow/claim-domain', data: {'domain': domain});
    return UserFlow.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 分析简历
  Future<Map<String, dynamic>> analyzeResume(Map<String, dynamic> data) async {
    final response = await _dio.post('/datasources/analyse', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 重置流程
  Future<Map<String, dynamic>> resetFlow() async {
    final response = await _dio.post('/flow/reset');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 生成 DINQ Card
  Future<Map<String, dynamic>> generate(Map<String, dynamic> data) async {
    final response = await _dio.post('/flow/generate', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}


