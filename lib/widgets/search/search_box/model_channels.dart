import '../../../models/deep_search_channel_models.dart';
import '../../../services/search_service.dart';

/// 与 TSX `useModelChannels.ts` ModelOption 对齐。
class ModelOption {
  const ModelOption({
    required this.value,
    required this.label,
    this.model,
    this.modelLabel,
    required this.displayLabel,
    this.iconAsset,
  });

  final String value;
  final String label;
  final String? model;
  final String? modelLabel;
  final String displayLabel;
  final String? iconAsset;
}

const _providerIconAssets = <String, String>{
  'anthropic': 'assets/icons/search/claude.svg',
  'anthropic-hao': 'assets/icons/search/claude.svg',
  'deepseek': 'assets/icons/search/deepseek.svg',
  'glm': 'assets/icons/search/glm.svg',
};

const _modelLabels = <String, String>{
  'deepseek-v4-flash[1m]': 'V4 Flash',
  'anthropic/claude-sonnet-4.6': 'Sonnet 4.6',
  'glm-5.1': '5.1',
};

String? modelLabelFor(String? model) {
  if (model == null || model.isEmpty) return null;
  return _modelLabels[model] ?? model;
}

/// 与 TSX FALLBACK_CHANNELS 对齐。
const fallbackChannelsResponse = DeepSearchChannelsResponse(
  defaultProvider: 'anthropic-hao',
  channels: [
    DeepSearchChannel(
      provider: 'deepseek',
      showName: 'DeepSeek',
      model: 'deepseek-v4-flash[1m]',
    ),
    DeepSearchChannel(
      provider: 'anthropic-hao',
      showName: 'Claude',
      model: 'anthropic/claude-sonnet-4.6',
      isDefault: true,
    ),
    DeepSearchChannel(
      provider: 'glm',
      showName: 'GLM',
      model: 'glm-5.1',
    ),
  ],
);

List<ModelOption> modelOptionsFromResponse(DeepSearchChannelsResponse source) {
  return source.channels.map((channel) {
    final label = channel.showName.isNotEmpty ? channel.showName : channel.provider;
    final modelLabel = modelLabelFor(channel.model);
    return ModelOption(
      value: channel.provider,
      label: label,
      model: channel.model,
      modelLabel: modelLabel,
      displayLabel: modelLabel != null ? '$label $modelLabel' : label,
      iconAsset: _providerIconAssets[channel.provider],
    );
  }).toList();
}

/// 拉取后端 model channel 列表；失败时使用 FALLBACK，5 分钟内存缓存。
class ModelChannelsCache {
  ModelChannelsCache._();
  static final instance = ModelChannelsCache._();

  static const _staleMs = 5 * 60 * 1000;

  List<ModelOption>? _options;
  String? _defaultProvider;
  int? _fetchedAtMs;

  List<ModelOption> get options =>
      _options ?? modelOptionsFromResponse(fallbackChannelsResponse);

  String get defaultProvider =>
      _defaultProvider ?? fallbackChannelsResponse.defaultProvider;

  bool get isStale {
    if (_fetchedAtMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch - _fetchedAtMs! > _staleMs;
  }

  Future<void> ensureLoaded({SearchService? searchService}) async {
    if (!isStale && _options != null) return;
    final service = searchService ?? SearchService();
    final response = await service.getDeepSearchChannels();
    final source = response ?? fallbackChannelsResponse;
    _options = modelOptionsFromResponse(source);
    _defaultProvider = source.defaultProvider.isNotEmpty
        ? source.defaultProvider
        : fallbackChannelsResponse.defaultProvider;
    _fetchedAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  void invalidate() {
    _options = null;
    _defaultProvider = null;
    _fetchedAtMs = null;
  }
}
