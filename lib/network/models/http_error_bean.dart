import 'http_result_base_bean.dart';

class HttpErrorBean extends HttpResultBaseBean {
  /// 响应完整json
  Map<String, dynamic>? errData;

  String? errorCode;

  HttpErrorBean({
    required super.status,
    required super.statusCode,
    required super.message,
    this.errorCode,
    this.errData,
  });

  @override
  String toString() {
    return '[$status] $message';
  }
}
