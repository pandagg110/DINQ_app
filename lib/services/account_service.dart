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

  /// GET /org/my — 我加入/创建的组织（含 role、member_count、pending_request_count）
  Future<List<dynamic>> getMyOrganizations() async {
    final resp = await _dio.get('/org/my');
    final data = resp.data;
    if (data is List) return data;
    if (data is Map && data['organizations'] is List) return data['organizations'] as List;
    return const [];
  }

  /// GET /orgs/{id}/members — 成员列表
  Future<List<dynamic>> getOrgMembers(String id) async {
    final resp = await _dio.get('/orgs/$id/members');
    final data = resp.data;
    if (data is List) return data;
    if (data is Map && data['members'] is List) return data['members'] as List;
    return const [];
  }

  /// POST /orgs/{id}/refresh-invite — 刷新邀请码（旧链接立即失效）。需 admin/owner。
  Future<String> refreshOrgInvite(String id) async {
    final resp = await _dio.post('/orgs/$id/refresh-invite');
    final data = resp.data;
    return (data is Map ? data['invite_code'] : '')?.toString() ?? '';
  }

  /// GET /orgs/{id}/requests — 入组申请列表（默认 pending）。需 admin/owner。
  Future<List<dynamic>> getOrgJoinRequests(String id, {String status = 'pending'}) async {
    final resp = await _dio.get('/orgs/$id/requests', queryParameters: {'status': status});
    final data = resp.data;
    if (data is List) return data;
    if (data is Map && data['requests'] is List) return data['requests'] as List;
    return const [];
  }

  /// POST /orgs/{id}/requests/{rid} — 审批入组申请。action: approved / rejected。
  Future<void> reviewOrgJoinRequest(String id, String rid, String action) async {
    await _dio.post('/orgs/$id/requests/$rid', data: {'action': action});
  }

  // ============== 简历 / Resume ==============

  /// GET /resumes — 简历列表
  Future<List<dynamic>> getResumes() async {
    final resp = await _dio.get('/resumes');
    final data = resp.data;
    return data is List ? data : const [];
  }

  /// POST /resumes — 创建简历（上传 PDF 后用 source_url 创建）
  Future<Map<String, dynamic>> createResume({
    required String title,
    required String sourceUrl,
    required String fileName,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/resumes',
      data: {'title': title, 'source_url': sourceUrl, 'file_name': fileName},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// GET /resumes/:id
  Future<Map<String, dynamic>> getResume(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>('/resumes/$id');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// PATCH /resumes/:id
  Future<Map<String, dynamic>> updateResume(
    String id, {
    String? title,
  }) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/resumes/$id',
      data: {if (title != null) 'title': title},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// DELETE /resumes/:id
  Future<void> deleteResume(String id) async {
    await _dio.delete('/resumes/$id');
  }

  // ============== 文件上传（OSS 预签名）==============

  /// POST /upload/url 取预签名 → PUT 字节到 OSS → 返回 file_url。
  Future<String> uploadFile({
    required String fileName,
    required int fileSize,
    required String contentType,
    required List<int> bytes,
    CancelToken? cancelToken,
  }) async {
    final tokenResp = await _dio.post<Map<String, dynamic>>(
      '/upload/url',
      data: {
        'file_name': fileName,
        'file_size': fileSize,
        'content_type': contentType,
      },
      cancelToken: cancelToken,
    );
    final data = tokenResp.data as Map<String, dynamic>;
    final uploadUrl = data['upload_url'] as String;
    final fileUrl = data['file_url'] as String;

    final ossDio = Dio();
    final putResp = await ossDio.put<void>(
      uploadUrl,
      data: Stream<List<int>>.fromIterable([bytes]),
      options: Options(
        contentType: contentType,
        headers: {Headers.contentLengthHeader: fileSize},
      ),
      cancelToken: cancelToken,
    );
    if (putResp.statusCode != 200) {
      throw Exception('OSS upload failed: ${putResp.statusCode}');
    }
    return fileUrl;
  }
}
