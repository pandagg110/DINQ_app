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
    // /orgs 实际返回 {organizations, total}（与 web ListOrgsResponse 一致）
    if (data is Map && data['organizations'] is List) return data['organizations'] as List;
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

  /// PUT /orgs/{id}/members/{uid}/role — 改成员角色（admin/member）。需 admin/owner。
  Future<void> updateOrgMemberRole(String id, String uid, String role) async {
    await _dio.put('/orgs/$id/members/$uid/role', data: {'role': role});
  }

  /// DELETE /orgs/{id}/members/{uid} — 移除成员。需 admin/owner，不能移除 owner。
  Future<void> removeOrgMember(String id, String uid) async {
    await _dio.delete('/orgs/$id/members/$uid');
  }

  /// PUT /orgs/{id} — 更新组织（部分字段：name/description/location/tags/
  /// logo_url/background_url 等）。需 admin/owner。对齐 web
  /// organizationApi.update（endpoints/organization.ts:60-61）。
  /// 注意：后端只回显提交的字段，调用方需本地合并（web updateField 同款做法）。
  Future<Map<String, dynamic>> updateOrg(
      String id, Map<String, dynamic> patch) async {
    final resp = await _dio.put('/orgs/$id', data: patch);
    final d = resp.data;
    return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
  }

  /// DELETE /orgs/{id} — 软删除组织。仅 owner。对齐 web
  /// organizationApi.remove（endpoints/organization.ts:66）。
  Future<void> deleteOrg(String id) async {
    await _dio.delete('/orgs/$id');
  }

  /// GET /org/profile?slug= — 组织公开档案（含 viewer 上下文：role/request_status）。
  Future<Map<String, dynamic>> getOrgProfile(String slug) async {
    final resp = await _dio.get('/org/profile', queryParameters: {'slug': slug});
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }

  /// GET /orgs/{id}/card-board — 组织卡片板（任意人可读，用于 Cards tab）。
  Future<List<dynamic>> getOrgCardBoard(String id) async {
    final resp = await _dio.get('/orgs/$id/card-board');
    final d = resp.data;
    if (d is Map && d['cards'] is List) return d['cards'] as List;
    return const [];
  }

  /// GET /orgs/{id}/team-recruits — 组队招募列表（仅成员可读）。
  /// 响应形如 { team_recruits: TeamRecruitSummary[], total, limit, offset }
  ///（对齐 web types/api/teamRecruit.ts ListOrgTeamRecruitsResponse）。
  Future<List<dynamic>> getOrgTeamRecruits(String id) async {
    final resp = await _dio.get('/orgs/$id/team-recruits');
    final d = resp.data;
    if (d is Map && d['team_recruits'] is List) return d['team_recruits'] as List;
    // 兼容旧字段名
    if (d is Map && d['recruits'] is List) return d['recruits'] as List;
    return const [];
  }

  /// POST /org — 创建组织。
  Future<Map<String, dynamic>> createOrg({
    required String name,
    required String slug,
    String? orgType,
    String? description,
    String? location,
    String? logoUrl,
    String? backgroundUrl,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>('/org', data: {
      'name': name,
      'slug': slug,
      if (orgType != null && orgType.isNotEmpty) 'org_type': orgType,
      if (description != null && description.isNotEmpty) 'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      if (logoUrl != null && logoUrl.isNotEmpty) 'logo_url': logoUrl,
      if (backgroundUrl != null && backgroundUrl.isNotEmpty) 'background_url': backgroundUrl,
    });
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }

  /// GET /org/check-slug?slug= — 检查 slug 可用性，返回 {available, suggestions}。
  Future<bool> checkOrgSlug(String slug) async {
    final resp = await _dio.get('/org/check-slug', queryParameters: {'slug': slug});
    final d = resp.data;
    return d is Map ? d['available'] == true : false;
  }

  /// GET /orgs?keyword=&limit=&offset= — 分页 + 关键词搜索组织列表。
  /// 对齐 web organizationApi.listAll(ListOrgsParams)（endpoints/organization.ts:128
  /// + types/api/organization.ts:81），返回 {organizations, total}。
  Future<Map<String, dynamic>> listOrgs(
      {String? keyword, int limit = 24, int offset = 0}) async {
    final resp = await _dio.get('/orgs', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'limit': limit,
      'offset': offset,
    });
    final d = resp.data;
    if (d is Map) {
      return {
        'organizations': d['organizations'] is List
            ? d['organizations'] as List
            : const <dynamic>[],
        'total': (d['total'] as num?)?.toInt() ?? 0,
      };
    }
    if (d is List) return {'organizations': d, 'total': d.length};
    return {'organizations': const <dynamic>[], 'total': 0};
  }

  /// GET /orgs — 发现所有可加入组织（公开），支持 keyword。
  Future<List<dynamic>> discoverOrgs({String? keyword}) async {
    final resp = await _dio.get('/orgs',
        queryParameters: {if (keyword != null && keyword.isNotEmpty) 'keyword': keyword});
    final d = resp.data;
    if (d is List) return d;
    if (d is Map && d['organizations'] is List) return d['organizations'] as List;
    return const [];
  }

  /// POST /orgs/{id}/request-join — 申请加入（无邀请码）。返回 status。
  Future<String> requestJoinOrg(String id) async {
    final resp = await _dio.post('/orgs/$id/request-join');
    final d = resp.data;
    return (d is Map ? d['status'] : '')?.toString() ?? '';
  }

  /// POST /org/join/{code} — 用邀请码加入。返回 status。
  Future<String> joinOrgByCode(String code) async {
    final resp = await _dio.post('/org/join/$code');
    final d = resp.data;
    return (d is Map ? d['status'] : '')?.toString() ?? '';
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
