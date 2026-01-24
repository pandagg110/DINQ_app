import '../http_code.dart';

class HttpResultBaseBean {
  /// 响应码
  HttpCode status;

  int? statusCode;

  /// 提示
  String message;

  HttpResultBaseBean({required this.status, required this.statusCode, required this.message});

  /// 是否请求成功
  bool isSuccess() {
    return HttpCode.success == status;
  }
}
