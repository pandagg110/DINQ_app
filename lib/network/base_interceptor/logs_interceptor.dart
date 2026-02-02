import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/logger_tool.dart';

class LogsInterceptor extends InterceptorsWrapper {
  bool get logEnabled => true;

  ///ConfigTool.shared.httpLogEnabled;

  @override
  onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    String url = options.path.startsWith(RegExp(r'https?:'))
        ? options.path
        : (options.baseUrl + options.path);
    if (options.data is FormData) {
      if (logEnabled && kDebugMode) {
        LoggerTool.d(
          '**************** onRequest *******************\n'
          'url：$url\n'
          'method: ${options.method}\n'
          'header: ${json.encode(options.headers)}\n'
          'params: ${options.data}',
        );
      }
    } else {
      if (logEnabled && kDebugMode) {
        LoggerTool.d(
          '**************** onRequest *******************\n'
          'url：$url\n'
          'method: ${options.method}\n'
          'header: ${json.encode(options.headers)}\n'
          'params: ${json.encode(options.data ?? (options.queryParameters))}',
        );
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  onResponse(Response response, ResponseInterceptorHandler handler) async {
    _printResponse(response);
    return super.onResponse(response, handler);
  }

  void _printResponse(Response response) {
    if (logEnabled && kDebugMode) {
      LoggerTool.d(
        '**************** onResponse ******************\n'
        'url: ${response.requestOptions.path}\n'
        'statusCode: ${response.statusCode}\n\n'
        'Response Text: ${response.toString()}',
      );
    }
    if (response.isRedirect == true) {
      if (kDebugMode) {
        LoggerTool.d('redirect: ${response.realUri}');
      }
    }
  }

  @override
  onError(DioException err, ErrorInterceptorHandler handler) async {
    if (logEnabled && kDebugMode) {
      LoggerTool.e(
        "**************** onError *********************\n"
        "err: ${err.toString()} \nres: ${err.response}",
      );
    }
    return super.onError(err, handler);
  }
}
