import 'package:dio/dio.dart';

import 'api_client.dart';

/// Talent Radar（持续找人 / scheduler task）接口。
/// 与 web DINQ_client task.ts 对齐：列表 / 创建 / 更新(暂停恢复) / 删除 / 事件日志。
class TaskService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /tasks — Radar 列表。后端返回可能包在 items/tasks/data 里。
  Future<List<dynamic>> listTasks() async {
    final resp = await _dio.get('/tasks');
    return _unwrapList(resp.data);
  }

  /// POST /tasks — 创建 Radar。data: { prompt, auto_search }
  Future<Map<String, dynamic>> createTask({
    required String prompt,
    bool autoSearch = true,
  }) async {
    final resp = await _dio.post('/tasks', data: {
      'prompt': prompt,
      'auto_search': autoSearch,
    });
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }

  /// PUT /tasks/{id} — 更新（暂停/恢复用 status: paused / active）。
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _dio.put('/tasks/$id', data: data);
  }

  Future<void> pauseTask(String id) => updateTask(id, {'status': 'paused'});
  Future<void> resumeTask(String id) => updateTask(id, {'status': 'active'});

  /// DELETE /scheduler/tasks/{id} — 删除 Radar。
  Future<void> deleteTask(String id) async {
    await _dio.delete('/scheduler/tasks/$id');
  }

  /// GET /tasks/{id}/events — 搜索日志（执行记录）。
  Future<List<dynamic>> getTaskEvents(String id) async {
    final resp = await _dio.get('/tasks/$id/events');
    return _unwrapList(resp.data);
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in ['items', 'tasks', 'records', 'results']) {
        if (data[k] is List) return data[k] as List;
      }
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['items'] is List) return inner['items'] as List;
    }
    return const [];
  }
}
