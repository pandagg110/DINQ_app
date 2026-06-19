import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';

class OnboardingService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getUploadUrl({
    required String fileName,
    required int fileSize,
    required String contentType,
  }) async {
    final response = await _dio.post('/onboarding/upload-url', data: {
      'file_name': fileName,
      'file_size': fileSize,
      'content_type': contentType,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> uploadResumeFile({
    required Uint8List bytes,
    required String filename,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final credentials = await getUploadUrl(
      fileName: filename,
      fileSize: bytes.length,
      contentType: 'application/pdf',
    );

    final uploadUrl = credentials['upload_url'] as String;
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
    ));

    await dio.put(
      uploadUrl,
      data: bytes,
      options: Options(headers: {'Content-Type': 'application/pdf'}),
      onSendProgress: onSendProgress,
    );

    return credentials;
  }

  Future<Map<String, dynamic>> createProfileDraft({
    required String sourceType,
    String? url,
    String? fileUrl,
    String? fileKey,
  }) async {
    final data = <String, dynamic>{'source_type': sourceType};
    if (url != null && url.isNotEmpty) data['url'] = url;
    if (fileUrl != null && fileUrl.isNotEmpty) data['file_url'] = fileUrl;
    if (fileKey != null && fileKey.isNotEmpty) data['file_key'] = fileKey;

    final response = await _dio.post('/onboarding/profile-draft', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> reserveHandle({required String handle}) async {
    final response = await _dio.post('/onboarding/handle-reservation', data: {
      'handle': handle,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }
}
