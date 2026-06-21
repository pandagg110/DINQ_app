/// Deep Search 模型通道类型，与 TSX `@/types/api/deep-search` 对齐。
library;

class DeepSearchChannel {
  const DeepSearchChannel({
    required this.provider,
    required this.showName,
    this.model,
    this.isDefault = false,
  });

  final String provider;
  final String showName;
  final String? model;
  final bool isDefault;

  factory DeepSearchChannel.fromJson(Map<String, dynamic> json) {
    return DeepSearchChannel(
      provider: json['provider']?.toString() ?? '',
      showName: json['show_name']?.toString() ?? json['provider']?.toString() ?? '',
      model: json['model']?.toString(),
      isDefault: json['is_default'] == true,
    );
  }
}

class DeepSearchChannelsResponse {
  const DeepSearchChannelsResponse({
    required this.defaultProvider,
    required this.channels,
  });

  final String defaultProvider;
  final List<DeepSearchChannel> channels;

  factory DeepSearchChannelsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['channels'];
    final channels = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => DeepSearchChannel.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.provider.isNotEmpty)
            .toList()
        : <DeepSearchChannel>[];
    return DeepSearchChannelsResponse(
      defaultProvider: json['default']?.toString() ?? '',
      channels: channels,
    );
  }
}
