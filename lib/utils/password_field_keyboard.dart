import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 小米 / HyperOS「安全键盘」下，Flutter `obscureText` 密码框首次
/// `showSoftInput` 常被 IMM 静默丢弃（已有焦点/光标，但键盘不弹，需再点一次）。
/// 见 https://github.com/flutter/flutter/issues/166311
///
/// 邮箱（普通键盘）↔ 密码（安全键盘）互切时同样会丢：两套 IME 切换窗口期内
/// 首次 showSoftInput 常被吞掉。互切时需先 hide 拆掉旧 IME，再延后 show。
const TextInputType kPasswordKeyboardType = TextInputType.visiblePassword;

void ensureSoftKeyboardVisible([FocusNode? focusNode]) {
  if (focusNode != null && !focusNode.hasFocus) return;
  SystemChannels.textInput.invokeMethod<void>('TextInput.show');
}

/// 兼容旧调用名。
void ensurePasswordSoftKeyboardVisible([FocusNode? focusNode]) =>
    ensureSoftKeyboardVisible(focusNode);

/// 获焦后多拍几次 show：覆盖首次弹出被丢弃的窗口期。
void scheduleSoftKeyboardRetries(FocusNode focusNode) {
  void tryShow() {
    if (focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  tryShow();
  SchedulerBinding.instance.addPostFrameCallback((_) => tryShow());
  for (final ms in [50, 120, 250, 400]) {
    Future<void>.delayed(Duration(milliseconds: ms), tryShow);
  }
}

/// 安全键盘 ↔ 普通键盘互切：先 hide 拆掉旧 IME，再延后多拍 show。
void scheduleImeSwitchSoftKeyboard(FocusNode focusNode) {
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

  void tryShow() {
    if (focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  SchedulerBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 60), tryShow);
  });
  // 覆盖 IMM 拆掉安全/普通键盘再挂上另一套的窗口期
  for (final ms in [100, 200, 320, 480, 650]) {
    Future<void>.delayed(Duration(milliseconds: ms), tryShow);
  }
}

/// 兼容旧调用名。
void schedulePasswordSoftKeyboardRetries(FocusNode focusNode) =>
    scheduleSoftKeyboardRetries(focusNode);
