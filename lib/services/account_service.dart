import 'package:dio/dio.dart';

import 'api_client.dart';

/// My 账户相关接口：邀请(referral) / API Keys / 组织(org)。
/// 与 DINQ_client 的 referralApi / apiKeysApi / organizationApi 对齐。
class AccountService {
  final Dio _dio = ApiClient.instance.dio;

  // ============== 邀请 / Referral ==============

  /// GET /referral/codes — 邀请码概览
  /// 返回 { total, used, left, total_rewards, codes:[{code, used_by_name, used_at}] }
  Future<Map<String, dynamic>> getReferralCodes() async {
    final resp = await _dio.get<Map<String, dynamic>>('/referral/codes');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// GET /referral/history — 邀请历史
  Future<List<dynamic>> getReferralHistory() async {
    final resp = await _dio.get('/referral/history');
    final data = resp.data;
    return data is List ? data : const [];
  }

  /// POST /referral/redeem — 兑换邀请码
  Future<void> redeemReferral(String code) async {
    await _dio.post('/referral/redeem', data: {'code': code});
  }

  // ============== API Keys ==============

  /// GET /api-keys — 列表，返回 { keys:[...], total }
  Future<List<dynamic>> getApiKeys() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api-keys');
    final data = resp.data as Map<String, dynamic>;
    final keys = data['keys'];
    return keys is List ? keys : const [];
  }

  /// POST /api-keys — 创建
  Future<Map<String, dynamic>> createApiKey([String? name]) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api-keys',
      data: {if (name != null) 'name': name},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// DELETE /api-keys/:id — 删除
  Future<void> deleteApiKey(int id) async {
    await _dio.delete('/api-keys/$id');
  }

  // ============== 组织 / Organization ==============

  /// GET /orgs — 我加入/创建的组织列表
  Future<List<dynamic>> getOrganizations() async {
    final resp = await _dio.get('/orgs');
    final data = resp.data;
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    if (data is Map && data['orgs'] is List) return data['orgs'] as List;
    return const [];
  }
}
