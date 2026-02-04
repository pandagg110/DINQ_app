import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取 OSS 上传凭证
  Future<Map<String, dynamic>> getUploadUrl({
    required String fileName,
    required int fileSize,
    required String contentType,
  }) async {
    final response = await _dio.post('/upload/url', data: {
      'file_name': fileName,
      'file_size': fileSize,
      'content_type': contentType,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 确认上传完成
  Future<Map<String, dynamic>> confirmUpload({
    required String fileUrl,
    required String fileName,
    required int fileSize,
  }) async {
    final response = await _dio.post('/upload/confirm', data: {
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 完整上传流程: 获取 OSS 凭证 → 上传文件
  /// 返回 OSS 上的文件 URL
  Future<String> uploadFile({
    required Uint8List bytes,
    required String filename,
    String? contentType,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    // Step 1: 获取 OSS 上传凭证
    final uploadToken = await getUploadUrl(
      fileName: filename,
      fileSize: bytes.length,
      contentType: contentType ?? 'application/octet-stream',
    );

    final uploadUrl = uploadToken['upload_url'] as String;
    final fileUrl = uploadToken['file_url'] as String;

    // Step 2: 使用预签名 URL 直接上传到 OSS
    // 创建新的 Dio 实例以避免拦截器干扰进度回调
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
    ));
    
    await dio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType ?? 'application/octet-stream',
        },
      ),
      onSendProgress: onSendProgress,
    );

    return fileUrl;
  }
}


