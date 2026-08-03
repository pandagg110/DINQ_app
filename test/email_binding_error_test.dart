import 'package:dinq_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email binding conflicts use a clear user-facing message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/change-email'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/auth/change-email'),
        statusCode: 409,
      ),
      error: 'Email is already bound to another account',
    );

    expect(
      bindEmailErrorMessage(error),
      'This email is already linked to another account. '
      'Please use a different email and try again.',
    );
  });

  test('email binding errors never expose DioException details', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/change-email'),
      type: DioExceptionType.connectionError,
    );

    final message = bindEmailErrorMessage(error);

    expect(message, 'Network error. Please check your connection.');
    expect(message, isNot(contains('DioException')));
  });

  test('email binding errors never expose backend implementation details', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/change-email'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/change-email'),
        statusCode: 500,
        data: {'message': 'failed to update email: database connection lost'},
      ),
    );

    expect(
      bindEmailErrorMessage(error),
      'Unable to update email. Please try again.',
    );
  });
}
