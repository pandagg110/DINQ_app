import 'package:flutter/material.dart';
import '../../cards/factory/card_definition.dart';

/// 卡片表单基础接口
/// 所有表单组件都应实现此接口
abstract class CardFormBase {
  /// 构建表单 Widget
  Widget build(BuildContext context, CardDefinition definition);

  /// 获取表单数据（在用户点击 Add 时调用）
  /// 返回 null 表示表单验证失败，否则返回表单数据 Map
  Future<Map<String, dynamic>?> getFormData();

  /// 表单的 FormKey（如果有的话，用于表单验证）
  GlobalKey<FormState>? get formKey => null;
}
