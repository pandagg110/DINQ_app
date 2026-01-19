import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$gatewayUrl/api/v1',
        connectTimeout: const Duration(milliseconds: ApiConfig.requestTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConfig.requestTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final data = response.data;
          if (data is Map<String, dynamic> && data.containsKey('code')) {
            if (data['code'] == 0) {
              return handler.next(response..data = data['data']);
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: data['message'] ?? 'Request failed',
              ),
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          if (status == 401 && _onUnauthorized != null) {
            _onUnauthorized!();
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  String? _authToken;
  UnauthorizedCallback? _onUnauthorized;

  Dio get dio => _dio;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setUnauthorizedHandler(UnauthorizedCallback? callback) {
    _onUnauthorized = callback;
  }
}


