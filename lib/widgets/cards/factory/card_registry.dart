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

  /// 适配后端返回的卡片数据
  CardItem adapt(CardItem card, ViewMode viewMode) {
    final type = card.data.type.toUpperCase();
    final definition = getDefinition(type);

    if (definition == null) {
      debugPrint('Warning: Card type "$type" is not registered.');
      return card;
    }

    // 如果定义了适配器，则适配 metadata
    // 对于 COMPLETED 状态的卡片，总是适配
    // 对于其他状态的卡片，如果 metadata 不完整（只有 type），也适配以填充默认值
    final adaptedMetadata = definition.adapt(card.data.metadata);
    if (adaptedMetadata != null) {
      final shouldAdapt = card.data.status == 'COMPLETED' ||
          // 对于客户端卡片（如 NOTE, MARKDOWN），如果 metadata 只有 type，需要适配
          (card.data.metadata.length <= 1 && card.data.metadata.containsKey('type'));
      
      if (shouldAdapt) {
        // 合并原始 metadata 和适配后的 metadata，保留原始数据中不在适配结果中的字段
        final mergedMetadata = {
          ...card.data.metadata,  // 先保留原始数据
          ...adaptedMetadata,      // 然后用适配后的数据覆盖
        };
        
        card = CardItem(
          id: card.id,
          data: CardData(
            id: card.data.id,
            type: card.data.type,
            title: card.data.title,
            description: card.data.description,
            metadata: mergedMetadata,  // 使用合并后的 metadata
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
