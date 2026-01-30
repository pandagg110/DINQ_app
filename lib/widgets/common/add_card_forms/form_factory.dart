import 'package:flutter/material.dart';
import '../../cards/factory/card_definition.dart';
import '../form_builder_widget.dart';
import 'card_form_base.dart';
import 'link_form.dart';
import 'markdown_form.dart';
import 'default_form.dart';

/// 表单工厂：根据卡片类型创建对应的表单组件
class CardFormFactory {
  /// 根据卡片类型创建表单
  static CardFormBase createForm({
    required String type,
    TextEditingController? controller,
    FocusNode? focusNode,
    GlobalKey<State<FormBuilderWidget>>? markdownFormKey,
  }) {
    final typeUpper = type.toUpperCase();
    
    if (typeUpper == 'LINK') {
      if (controller == null || focusNode == null) {
        throw ArgumentError('LinkForm requires controller and focusNode');
      }
      return LinkForm(controller: controller, focusNode: focusNode);
    } else if (typeUpper == 'MARKDOWN') {
      if (markdownFormKey == null) {
        throw ArgumentError('MarkdownForm requires markdownFormKey');
      }
      return MarkdownForm(formKey: markdownFormKey);
    } else {
      if (controller == null || focusNode == null) {
        throw ArgumentError('DefaultForm requires controller and focusNode');
      }
      return DefaultForm(controller: controller, focusNode: focusNode);
    }
  }
}
