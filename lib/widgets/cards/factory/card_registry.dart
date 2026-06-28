import 'package:flutter/foundation.dart';
import '../../../models/card_models.dart';
import 'card_definition.dart';

/// 卡片注册表 - 中央注册表
/// 管理所有卡片类型的定义
class CardRegistry {
  static final CardRegistry _instance = CardRegistry._internal();
  factory CardRegistry() => _instance;
  CardRegistry._internal();

  final Map<String, CardDefinition> _definitions = {};

  /// 注册卡片定义
  void register(CardDefinition definition) {
    _definitions[definition.type.toUpperCase()] = definition;
  }

  /// 获取卡片定义
  CardDefinition? getDefinition(String type) {
    return _definitions[type.toUpperCase()];
  }

  /// 适配后端返回的卡片数据（对齐 Web adaptCard：仅 COMPLETED 或无 status 时适配 metadata）
  CardItem adapt(CardItem card, ViewMode viewMode) {
    final type = card.data.type.toUpperCase();
    final definition = getDefinition(type);

    if (definition == null) {
      debugPrint('Warning: Card type "$type" is not registered.');
      return card;
    }

    if (card.data.status == 'COMPLETED' || card.data.status.isEmpty) {
      final unwrapped = unwrapEnvelope(card.data.metadata);
      final adaptedMetadata = definition.adapt(unwrapped);
      if (adaptedMetadata != null) {
        final preservedUrl = card.data.metadata['url'];
        final preservedDisplayMode = card.data.metadata['displayMode'];
        final metadata = Map<String, dynamic>.from(adaptedMetadata);
        if (preservedUrl != null && preservedUrl.toString().isNotEmpty) {
          metadata['url'] = preservedUrl;
        }
        if (preservedDisplayMode != null) {
          metadata['displayMode'] = preservedDisplayMode;
        }

        card = CardItem(
          id: card.id,
          data: CardData(
            id: card.data.id,
            type: card.data.type,
            title: card.data.title,
            description: card.data.description,
            metadata: metadata,
            status: card.data.status,
          ),
          layout: card.layout,
        );
      }
    }

    // 适配 layout - 确保尺寸在支持的范围内
    final sizeConfig = viewMode == ViewMode.desktop
        ? definition.sizes.desktop
        : definition.sizes.mobile;
    final currentSize = viewMode == ViewMode.desktop
        ? card.layout.desktop.size
        : card.layout.mobile.size;

    // 检查当前尺寸是否在支持的尺寸列表中
    if (!sizeConfig.supported.contains(currentSize)) {
      final layoutState = viewMode == ViewMode.desktop
          ? card.layout.desktop
          : card.layout.mobile;
      final newLayoutState = CardLayoutState(
        size: sizeConfig.defaultSize,
        position: layoutState.position,
      );

      if (viewMode == ViewMode.desktop) {
        card = CardItem(
          id: card.id,
          data: card.data,
          layout: CardLayout(
            desktop: newLayoutState,
            mobile: card.layout.mobile,
          ),
        );
      } else {
        card = CardItem(
          id: card.id,
          data: card.data,
          layout: CardLayout(
            desktop: card.layout.desktop,
            mobile: newLayoutState,
          ),
        );
      }
    }

    return card;
  }

  /// 剥离后端 `{ code, message, data }` 信封（对齐 Web adapters.unwrapEnvelope）
  static dynamic unwrapEnvelope(dynamic raw) {
    if (raw == null || raw is! Map) return raw;
    if (!raw.containsKey('code') && !raw.containsKey('message')) return raw;

    final inner = raw['data'];
    if (inner == null) return raw;
    if (inner is List) return inner;
    if (inner is Map) {
      final rest = Map<String, dynamic>.from(raw);
      rest.remove('code');
      rest.remove('message');
      rest.remove('data');
      return {...Map<String, dynamic>.from(inner), ...rest};
    }
    return raw;
  }

  /// 创建新卡片
  Future<CardItem> create(
    String type,
    Map<String, dynamic> metadata,
    List<CardItem> existingCards,
  ) async {
    final def = getDefinition(type.toUpperCase());
    if (def == null) {
      throw Exception('Card type "$type" is not registered.');
    }

    // 构造默认 metadata
    Map<String, dynamic> defaultMeta = {'type': type};
    final createdMeta = await def.create();
    if (createdMeta != null) {
      defaultMeta = {...defaultMeta, ...createdMeta};
    }
    final finalMeta = {...defaultMeta, ...metadata};

    // 验证 metadata
    final validationResult = def.validate(finalMeta);
    if (validationResult != null) {
      throw Exception('Params Validation Failed: $validationResult');
    }

    final id = 'mock-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecondsSinceEpoch}';

    // 获取默认尺寸
    final desktopSize = def.sizes.desktop.defaultSize;
    final mobileSize = def.sizes.mobile.defaultSize;

    // 计算位置（简化版，实际应该使用 findCardPosition）
    final desktopPosition = CardPosition(x: 0, y: 0, w: 2, h: 2);
    final mobilePosition = CardPosition(x: 0, y: 0, w: 2, h: 2);

    return CardItem(
      id: id,
      data: CardData(
        id: id,
        type: type,
        title: finalMeta['title']?.toString() ?? '',
        description: finalMeta['description']?.toString() ?? '',
        metadata: finalMeta,
        status: 'PROCESSING',
      ),
      layout: CardLayout(
        desktop: CardLayoutState(
          size: desktopSize,
          position: desktopPosition,
        ),
        mobile: CardLayoutState(
          size: mobileSize,
          position: mobilePosition,
        ),
      ),
    );
  }

  /// 获取所有已注册的卡片类型
  List<String> getRegisteredTypes() {
    return _definitions.keys.toList();
  }

  /// 检查卡片类型是否已注册
  bool isRegistered(String type) {
    return _definitions.containsKey(type.toUpperCase());
  }

  /// 初始化注册表 - 注册所有卡片定义
  void initialize() {
    // 这里会在 definitions/index.dart 中调用
  }
}
