import 'package:dio/dio.dart';

import 'api_client.dart';

/// Outreach API，对齐 Web `outreach.ts`。
class OutreachService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> generate({
    required String userContext,
    required String style,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/outreach/generate',
      data: {
        'user_context': userContext,
        'style': style,
      },
    );
    return Map<String, dynamic>.from(response.data ?? const {});
  }

  Future<void> contact({
    required String type,
    required String email,
    required String subject,
    required String content,
    String? senderEmail,
    String? senderName,
    String? favoriteId,
  }) async {
    await _dio.post<void>(
      '/outreach/contact',
      data: {
        'type': type,
        'email': email,
        'subject': subject,
        'content': content,
        if (senderEmail != null) 'sender_email': senderEmail,
        if (senderName != null) 'sender_name': senderName,
        if (favoriteId != null) 'favorite_id': favoriteId,
      },
    );
  }
}
