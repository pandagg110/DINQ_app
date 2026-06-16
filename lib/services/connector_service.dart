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
}

class EmailSetting {
  const EmailSetting({
    required this.email,
    this.displayName,
    this.signature,
  });

  final String email;
  final String? displayName;
  final String? signature;

  factory EmailSetting.fromJson(Map<String, dynamic> json) {
    return EmailSetting(
      email: (json['email'] ?? '').toString(),
      displayName: json['displayName']?.toString(),
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
}
