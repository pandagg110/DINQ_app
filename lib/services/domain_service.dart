import 'package:dio/dio.dart';

import 'api_client.dart';

/// POST /app/domain/resolve 返回的域名类型。
enum DomainResolveType {
  personal,
  organization,
  system,
  unknown;

  static DomainResolveType fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'personal':
        return DomainResolveType.personal;
      case 'organization':
        return DomainResolveType.organization;
      case 'system':
        return DomainResolveType.system;
      default:
        return DomainResolveType.unknown;
    }
  }

  bool get isInAppProfile =>
      this == DomainResolveType.personal ||
      this == DomainResolveType.organization;
}

class DomainResolveResult {
  const DomainResolveResult({
    required this.type,
    required this.domain,
  });

  factory DomainResolveResult.fromJson(Map<String, dynamic> json) {
    return DomainResolveResult(
      type: DomainResolveType.fromString(json['type']?.toString()),
      domain: json['domain']?.toString() ?? '',
    );
  }

  final DomainResolveType type;
  final String domain;
}

/// 域名识别：无需登录。
class DomainService {
  DomainService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// POST /api/v1/app/domain/resolve
  Future<DomainResolveResult> resolve(String domain) async {
    final response = await _dio.post(
      '/app/domain/resolve',
      data: {'domain': domain},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return DomainResolveResult.fromJson(data);
    }
    if (data is Map) {
      return DomainResolveResult.fromJson(Map<String, dynamic>.from(data));
    }
    return const DomainResolveResult(
      type: DomainResolveType.unknown,
      domain: '',
    );
  }
}
