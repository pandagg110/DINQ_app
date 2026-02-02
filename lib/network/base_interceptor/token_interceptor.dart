import 'package:dio/dio.dart';

class TokenInterceptor extends QueuedInterceptorsWrapper {
  final Dio tokenDio;

  TokenInterceptor({required this.tokenDio});

  @override
  onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // String url =
    //     options.path.startsWith(RegExp(r'https?:'))
    //         ? options.path
    //         : (options.baseUrl + options.path);
    // if (![
    //   UserURLs.refreshTokenUrl,
    //   UserURLs.emailLoginUrl,
    //   UserURLs.registerEmailUrl,
    // ].contains(url)) {
    //   await UserRepo.shared.checkAndRefreshToken();
    // }
    // if (UserRepo.shared.currentUser?.sign != null) {
    //   options.headers["Authorization"] = UserRepo.shared.currentUser!.sign;
    // }
    handler.next(options);
  }

  @override
  onResponse(Response response, ResponseInterceptorHandler handler) async {
    handler.next(response);
  }
}
