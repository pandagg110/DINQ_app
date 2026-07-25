import 'package:flutter/widgets.dart';

/// [TextField.onTapOutside]：点输入框外收起键盘（替代 KeyboardDismissOnTap）。
void unfocusOnTapOutside(PointerDownEvent _) {
  FocusManager.instance.primaryFocus?.unfocus();
}
