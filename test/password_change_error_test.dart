import 'package:dinq_app/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException responseError({
    required int statusCode,
    required String message,
  }) {
    final options = RequestOptions(path: '/auth/change-password');
    return DioException(
      requestOptions: options,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: statusCode,
        data: {'code': statusCode, 'data': null, 'message': message},
      ),
    );
  }

  test('asks for the current password when account state was stale', () {
    final error = responseError(
      statusCode: 400,
      message: 'current password is required',
    );

    expect(passwordChangeRequiresCurrentPassword(error), isTrue);
    expect(
      passwordChangeErrorMessage(error),
      'Please enter your current password.',
    );
  });

  test('shows a clear message for an incorrect current password', () {
    final error = responseError(
      statusCode: 400,
      message: 'current password is incorrect',
    );

    expect(passwordChangeErrorMessage(error), 'Current password is incorrect.');
  });

  test('does not expose DioException details for generic bad requests', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/change-password'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/auth/change-password'),
        statusCode: 400,
      ),
    );

    final message = passwordChangeErrorMessage(error);

    expect(message, 'Unable to update password. Please check your input.');
    expect(message, isNot(contains('DioException')));
  });

  test('does not expose backend implementation details', () {
    final error = responseError(
      statusCode: 500,
      message: 'failed to update password: database connection lost',
    );

    expect(
      passwordChangeErrorMessage(error),
      'Unable to update password. Please try again.',
    );
  });
}
