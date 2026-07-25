import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// [TextField.onTapOutside]：点输入框外收起键盘（替代 KeyboardDismissOnTap）。
///
/// 延后到本帧结束后再判断：若焦点已落到其它控件（典型：密码→邮箱），
/// 则不再 unfocus，避免先收起安全键盘导致新输入框弹不出面板。
void unfocusOnTapOutside(PointerDownEvent _) {
  final FocusNode? before = FocusManager.instance.primaryFocus;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final FocusNode? after = FocusManager.instance.primaryFocus;
    // 焦点已转移给其它输入框：放行，由新框负责弹出键盘。
    if (after != null && !identical(after, before)) return;
    after?.unfocus();
  });
}
