import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 小米 / HyperOS「安全键盘」下，Flutter `obscureText` 密码框首次
/// `showSoftInput` 常被 IMM 静默丢弃（已有焦点/光标，但键盘不弹，需再点一次）。
/// 见 https://github.com/flutter/flutter/issues/166311
const TextInputType kPasswordKeyboardType = TextInputType.visiblePassword;

void ensurePasswordSoftKeyboardVisible([FocusNode? focusNode]) {
  if (focusNode != null && !focusNode.hasFocus) return;
  SystemChannels.textInput.invokeMethod<void>('TextInput.show');
}

/// 获焦后多拍几次 show：对齐「第二次点击才弹出」的平台行为。
void schedulePasswordSoftKeyboardRetries(FocusNode focusNode) {
  void tryShow() {
    if (focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  // 当前帧末 + 短延迟，覆盖 IMM 切换安全键盘的窗口期
  SchedulerBinding.instance.addPostFrameCallback((_) => tryShow());
  for (final ms in [50, 120, 250]) {
    Future<void>.delayed(Duration(milliseconds: ms), tryShow);
  }
}
