import 'package:dio/dio.dart';

import 'api_client.dart';

class ConnectorAccount {
  const ConnectorAccount({
    required this.id,
    required this.platform,
    required this.status,
    this.accountEmail,
  });

  final String id;
  final String platform;
  final String status;
  final String? accountEmail;

  factory ConnectorAccount.fromJson(Map<String, dynamic> json) {
    return ConnectorAccount(
      id: (json['id'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      accountEmail: json['account_email']?.toString(),
    );
  }
}

/// Connector API，对齐 Web `connector.ts`（经网关 /connector）。
class ConnectorService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ConnectorAccount>> getAccounts() async {
    final response = await _dio.get<Map<String, dynamic>>('/connector/auth/accounts');
    final data = response.data;
    final accounts = data?['accounts'];
    if (accounts is! List) return const [];
    return accounts
        .whereType<Map>()
        .map((e) => ConnectorAccount.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 发起连接，返回 OAuth 跳转地址（platform: gmail/microsoft/imap）。
  Future<String?> initiateConnect(String platform, String callbackUrl) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/connector/auth/connect',
      data: {'platform': platform, 'callback_url': callbackUrl},
    );
    return response.data?['redirect_url']?.toString();
  }

  /// 断开某个已连接账号。
  Future<void> disconnect(String accountId) async {
    await _dio.delete('/connector/auth/accounts/$accountId');
  }
}

class EmailSetting {
  const EmailSetting({
    required this.id,
    required this.email,
    this.displayName,
    this.signature,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? signature;

  factory EmailSetting.fromJson(Map<String, dynamic> json) {
    return EmailSetting(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['display_name'])?.toString(),
      signature: json['signature']?.toString(),
    );
  }
}

class EmailSettingsService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<EmailSetting>> list() async {
    final response = await _dio.get<dynamic>('/email-settings');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => EmailSetting.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => EmailSetting.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  /// 更新发件人显示名/签名。
  Future<void> update(String id, {String? displayName, String? signature}) async {
    await _dio.put('/email-settings/$id', data: {
      if (displayName != null) 'display_name': displayName,
      if (signature != null) 'signature': signature,
    });
  }
}
