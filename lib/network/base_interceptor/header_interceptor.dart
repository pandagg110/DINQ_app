import 'package:dio/dio.dart';

import '../network_tool.dart';

class HeaderInterceptor extends InterceptorsWrapper {
  @override
  onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    Map<String, dynamic> params = {};
    if (NetworkTool.methodGet == options.method) {
      final queryParameters = Map<String, dynamic>.from(options.queryParameters);
      final urlQueryParameters = options.uri.queryParameters;
      for (final o in params.keys) {
        if (urlQueryParameters[o] == null) {
          queryParameters[o] = params[o];
        }
      }
      options.queryParameters = queryParameters;
    } else if (options.data is Map<String, dynamic>) {
      options.data = (Map<String, dynamic>.from(options.data ?? {}))..addAll(params);
    }

    var headers = params;

    /// 添加请求头
    options.headers.addAll(headers);

    return super.onRequest(options, handler);
  }
}
