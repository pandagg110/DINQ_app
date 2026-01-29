import 'package:flutter/material.dart';
import '../../../models/card_models.dart';

/// 卡片尺寸配置
class CardSizeConfig {
  final List<String> supported;
  final String defaultSize;

  const CardSizeConfig({
    required this.supported,
    required this.defaultSize,
  });
}

/// 卡片视图模式尺寸配置
class CardViewModeSizes {
  final CardSizeConfig desktop;
  final CardSizeConfig mobile;

  const CardViewModeSizes({
    required this.desktop,
    required this.mobile,
  });
}

/// 卡片渲染参数
class CardRenderParams {
  final CardItem card;
  final String size;
  final bool editable;
  final bool isSelected;
  final Function(Map<String, dynamic>) onUpdate;

  const CardRenderParams({
    required this.card,
    required this.size,
    required this.editable,
    this.isSelected = false,
    required this.onUpdate,
  });
}

/// 卡片定义抽象类
abstract class CardDefinition {
  /// 卡片类型标识
  String get type;

  /// 显示图标路径
  String get icon;

  /// 显示名称
  String get name;

  /// 尺寸配置
  CardViewModeSizes get sizes;

  /// 数据适配器（可选）
  /// 将后端API返回的raw_metadata转换为Card的metadata格式
  /// rawMetadata 可以是 Map 或 List（如 career_trajectory 的数组类型）
  Map<String, dynamic>? adapt(dynamic rawMetadata) => null;

  /// 创建策略（可选）
  /// 构造默认的metadata数据
  Future<Map<String, dynamic>>? create() => null;

  /// 验证函数（可选）
  /// 在 create 执行后验证返回的 metadata 是否有效
  /// 返回 null 表示验证通过，返回字符串表示错误信息
  String? validate(Map<String, dynamic> metadata) => null;

  /// 渲染函数
  /// 返回Card的UI组件
  Widget render(CardRenderParams params);
}

