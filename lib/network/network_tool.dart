import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger_tool.dart';
import './base_interceptor/token_interceptor.dart';
import 'base_interceptor/header_interceptor.dart';
import 'base_interceptor/logs_interceptor.dart';
import 'http_code.dart';
import 'models/http_error_bean.dart';
import 'util/bean_factory.dart';

export './models/http_error_bean.dart';

class NetworkTool {
  static const methodPost = "POST";
  static const methodGet = "GET";
  static const methodPatch = "PATCH";
  static const methodPut = "PUT";
  static const methodDelete = "DELETE";

  static NetworkTool? _instance = NetworkTool._internal();

  static NetworkTool get shared => _instance ?? NetworkTool._internal();

  factory NetworkTool() => _instance ?? NetworkTool._internal();

  late final Dio _dio;
  late final Dio _tokenDio;
  List<CancelToken> _cancelTokenList = [];

  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
    _tokenDio.options.baseUrl = baseUrl;
  }

  NetworkTool._internal() {
    _dio = Dio();
    _tokenDio = Dio();

    _dio.interceptors.add(TokenInterceptor(tokenDio: _tokenDio));
    _dio.interceptors.add(HeaderInterceptor());
    _dio.interceptors.add(LogsInterceptor());

    _tokenDio.interceptors.add(HeaderInterceptor());
    _tokenDio.interceptors.add(LogsInterceptor());
  }

  void setProxy(String proxy) {
    _instance = null;
  }

  /// 请求列表, 请求是否成功，数据列表，错误信息，总量
  Future<(bool, List<T>?, HttpErrorBean?, int?)> requestList<T>(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? header,
    FormData? formData,
    String? method = NetworkTool.methodGet,
    Options? options,
    int connectTimeout = 30,
    int receiveTimeout = 30,
    bool? isCheckNetwork,
    CancelToken? cancelToken,
    bool tokenDio = false,
  }) async {
    options = _composeRequestOptions(
      header: header,
      method: method,
      options: options,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      cancelToken: cancelToken,
      tokenDio: tokenDio,
    );

    // 添加CancelToken, 用于取消请求
    cancelToken ??= CancelToken();
    _cancelTokenList = [];
    _cancelTokenList.add(cancelToken);

    bool isSuccess = false;
    List<T>? result;
    HttpErrorBean? errorBean;
    int? totalCount;
    try {
      Response response = await _sendRequest(
        url,
        data: formData,
        parameters: params,
        cancelToken: cancelToken,
        options: options,
        tokenDio: tokenDio,
      );
      if (response.data is Map<String, dynamic>) {
        if (response.data["code"] == 200 || response.data["code"] == 0) {
          isSuccess = true;
          List dataList = [];
          result = [];
          totalCount = 0;
          if (response.data["dataList"] is List) {
            dataList = response.data["dataList"];
          } else if (response.data["data"] != null) {
            if (response.data["data"] is List) {
              dataList = response.data["data"];
            } else if (response.data["data"] is Map) {
              final data = response.data["data"];
              if (data["total"] is int) {
                totalCount = data["total"];
              }
              if (data["list"] is List) {
                dataList = data["list"];
              } else if (data["dataList"] is List) {
                dataList = data["dataList"];
              } else if (data["records"] is List) {
                dataList = data["records"];
              } else if (data["orders"] is List) {
                dataList = data["orders"];
              } else if (data["pendings"] is List) {
                dataList = data["pendings"];
              } else if (data["bills"] is List) {
                dataList = data["bills"];
              }
            }
          }
          for (final dict in dataList) {
            T obj = BeanFactory.parseObject<T>(dict);
            result.add(obj);
          }
        } else {
          errorBean = _dealBusinessErrorEntity(response.data, response.statusCode);
        }
      } else {
        errorBean = HttpErrorBean(
          status: HttpCode.other,
          statusCode: response.statusCode,
          message: 'Unknown Error',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        LoggerTool.e("DioException: url: $url, ${e.toString()}");
      }
      isSuccess = false;
      errorBean = _dealHttpErrorEntity(e);
    } catch (exception) {
      if (kDebugMode) {
        LoggerTool.e("Request Exception: url: $url, ${exception.toString()}");
      }
      isSuccess = false;
      errorBean = HttpErrorBean(
        status: HttpCode.other,
        statusCode: null,
        message: exception.toString(),
      );
    } finally {
      // 请求完成移除cancelToken
      if (_cancelTokenList.contains(cancelToken)) {
        _cancelTokenList.remove(cancelToken);
      }
    }
    return (isSuccess, result, errorBean, totalCount);
  }

  Future<(bool, T?, HttpErrorBean?)> request<T>(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? header,
    Object? formData,
    String? method = NetworkTool.methodGet,
    Options? options,
    int connectTimeout = 30,
    int receiveTimeout = 30,
    bool? isCheckNetwork,
    CancelToken? cancelToken,
    bool tokenDio = false,
  }) async {
    options = _composeRequestOptions(
      header: header,
      method: method,
      options: options,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      cancelToken: cancelToken,
      tokenDio: tokenDio,
    );

    // 添加CancelToken, 用于取消请求
    cancelToken ??= CancelToken();
    _cancelTokenList = [];
    _cancelTokenList.add(cancelToken);

    bool isSuccess = false;
    T? result;
    HttpErrorBean? errorBean;

    try {
      Response response = await _sendRequest(
        url,
        data: formData,
        parameters: params,
        cancelToken: cancelToken,
        options: options,
        tokenDio: tokenDio,
      );
      if (response.data is Map<String, dynamic>) {
        if (response.data["code"] == 200 || response.data["code"] == 0) {
          isSuccess = true;
          if (response.data["data"] is Map<String, dynamic>) {
            result = BeanFactory.parseObject<T>(response.data["data"]);
          } else {
            result = response.data["data"];
          }
        } else {
          errorBean = _dealBusinessErrorEntity(response.data, response.statusCode);
        }
      } else {
        errorBean = HttpErrorBean(
          status: HttpCode.other,
          statusCode: response.statusCode,
          message: 'Unknown Error',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        LoggerTool.e("DioException: url: $url, ${e.toString()}");
      }
      isSuccess = false;
      errorBean = _dealHttpErrorEntity(e);
    } catch (exception) {
      if (kDebugMode) {
        LoggerTool.e("Request Exception: url: $url, ${exception.toString()}");
      }
      isSuccess = false;
      errorBean = HttpErrorBean(
        status: HttpCode.other,
        statusCode: null,
        message: exception.toString(),
      );
    } finally {
      // 请求完成移除cancelToken
      if (_cancelTokenList.contains(cancelToken)) {
        _cancelTokenList.remove(cancelToken);
      }
    }
    return (isSuccess, result, errorBean);
  }

  Options _composeRequestOptions({
    Map<String, dynamic>? header,
    String? method = NetworkTool.methodGet,
    Options? options,
    int connectTimeout = 30,
    int receiveTimeout = 30,
    CancelToken? cancelToken,
    bool tokenDio = false,
  }) {
    final Dio dio = tokenDio ? _tokenDio : _dio;
    options ??= Options();
    options.receiveTimeout = Duration(seconds: receiveTimeout);
    dio.options.connectTimeout = Duration(seconds: connectTimeout);

    options.headers ??= {};
    // 处理请求头
    if (header != null) {
      options.headers!.addAll(header);
    }

    options.method = method;
    return options;
  }

  Future<Response> _sendRequest(
    String url, {
    Object? data,
    Map<String, dynamic>? parameters,
    CancelToken? cancelToken,
    Options? options,
    bool tokenDio = false,
  }) async {
    final Dio dio = tokenDio ? _tokenDio : _dio;
    Response response;
    if (options?.method == NetworkTool.methodGet) {
      response = await dio.get(url, queryParameters: parameters, options: options);
    } else {
      response = await dio.request(url, data: data ?? parameters, options: options);
    }
    return response;
  }

  /// 上传图片
  Future<(bool, Map<String, dynamic>?, HttpErrorBean?)> uploadImage(
    String urlString, {
    Map<String, dynamic>? params,
    required String key,
    required File imageFile,
    CancelToken? cancelToken,
    bool tokenDio = false,
  }) async {
    final Map<String, dynamic> body = params ?? {};
    body[key] = await MultipartFile.fromFile(
      imageFile.path,
      filename: "image.jpeg",
      contentType: DioMediaType("image", "jpeg"),
    );
    FormData formData = FormData.fromMap(body);
    final res = await request<Map<String, dynamic>>(
      urlString,
      formData: formData,
      params: params,
      method: NetworkTool.methodPost,
      cancelToken: cancelToken,
      connectTimeout: 60,
      receiveTimeout: 60,
      tokenDio: tokenDio,
    );
    return res;
  }

  /// 取消所有请求
  void cancelAll() {
    if (kDebugMode) {
      LoggerTool.i('cancelAll:${_cancelTokenList.length}');
    }
    for (var cancelToken in _cancelTokenList) {
      cancel(cancelToken);
    }
    _cancelTokenList.clear();
  }

  /// 取消指定的请求
  void cancel(CancelToken cancelToken) {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel();
    }
  }

  /// 取消指定的请求
  void cancelList(List<CancelToken> cancelTokenList) {
    if (kDebugMode) {
      LoggerTool.i('cancelList:${cancelTokenList.length}');
    }
    for (var cancelToken in cancelTokenList) {
      cancel(cancelToken);
    }
  }

  /// 请求后端返回失败
  HttpErrorBean _dealBusinessErrorEntity(Map<String, dynamic> error, int? responseCode) {
    if (error["code"] == 200) {
      return HttpErrorBean(status: HttpCode.success, statusCode: responseCode, message: '');
    } else {
      return HttpErrorBean(
        status: HttpCode.paramError,
        statusCode: responseCode,
        message: error["message"] ?? (error["msg"] ?? 'Unknown Error'),
        errorCode: error["code"].toString(),
        errData: error,
      );
    }
  }

  /// 请求本身失败时触发
  HttpErrorBean _dealHttpErrorEntity(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return HttpErrorBean(
          status: HttpCode.connectTimeout,
          statusCode: null,
          message: 'Network Error',
        );
      case DioExceptionType.sendTimeout:
        return HttpErrorBean(
          status: HttpCode.sendTimeout,
          statusCode: null,
          message: 'Network Error',
        );
      case DioExceptionType.receiveTimeout:
        return HttpErrorBean(
          status: HttpCode.receiveTimeout,
          statusCode: null,
          message: 'Network Error',
        );
      case DioExceptionType.badResponse:
        if (error.response != null) {
          final res = error.response!.data;
          if (res is Map<String, dynamic>) {
            // if (res['code'] == 401 || res['code'] == 2001 || res['code'] == 13) {
            //   bool isLogin = UserRepo.shared.currentUser != null;
            //   if (isLogin) {
            //     UserRepo.shared.logout();
            //   }
            // }
            final error = res["error"] ?? res;
            return HttpErrorBean(
              status: HttpCode.paramError,
              statusCode: null,
              message: error["message"] ?? (error["message"] ?? "Unknown Error"),
              errorCode: error["code"].toString(),
              errData: error,
            );
          } else if (res.toString().contains("EntityTooLarge")) {
            return HttpErrorBean(
              status: HttpCode.other,
              statusCode: null,
              message: "EntityTooLarge",
              errorCode: "-10001",
            );
          }
        }
        return HttpErrorBean(
          status: HttpCode.serverError,
          statusCode: null,
          message: error.toString(),
        );
      case DioExceptionType.badCertificate:
        break;
      case DioExceptionType.unknown:
        break;
      case DioExceptionType.cancel:
        return HttpErrorBean(status: HttpCode.cancel, statusCode: null, message: error.toString());
    }
    return HttpErrorBean(status: HttpCode.other, statusCode: null, message: error.toString());
  }
}
