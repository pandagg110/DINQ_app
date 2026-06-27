import 'package:dio/dio.dart';

/// 把异常转成对用户友好的提示文案。
/// 优先取后端返回的 `message`/`error` 字段；否则按状态码兜底，
/// 绝不把原始 DioException 堆栈直接抛给用户。
String apiErrorMessage(Object? error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is DioException) {
    // 1) 拦截器 reject 时塞进 error 的服务端 message
    final e = error.error;
    if (e is String && e.isNotEmpty && !e.startsWith('DioException')) return e;

    // 2) 响应体里的 message / error 字段
    final data = error.response?.data;
    if (data is Map) {
      for (final k in const ['message', 'error', 'msg', 'detail']) {
        final v = data[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    if (data is String && data.isNotEmpty && data.length < 200) return data;

    // 3) 按状态码兜底
    final code = error.response?.statusCode;
    if (code == 400) return 'Invalid request. Please check your input.';
    if (code == 401) return 'Authentication failed. Please sign in again.';
    if (code == 403) return 'You do not have permission to do this.';
    if (code == 404) return 'Not found.';
    if (code == 409) return 'This already exists.';
    if (code != null && code >= 500) return 'Server error. Please try again later.';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your connection.';
      default:
        break;
    }
  }
  return fallback;
}
