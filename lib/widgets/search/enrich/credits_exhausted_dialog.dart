import 'package:flutter/material.dart';

import 'credits_exhausted_sheet.dart';

export 'credits_exhausted_sheet.dart'
    show CreditsExhaustedReason, showCreditsExhaustedSheet;

/// 兼容旧调用：转发至 Bottom Sheet 卡点弹窗。
@Deprecated('Use showCreditsExhaustedSheet instead')
Future<void> showCreditsExhaustedDialog(
  BuildContext context, {
  required String reason,
}) {
  final parsed = reason == 'email'
      ? CreditsExhaustedReason.email
      : CreditsExhaustedReason.search;
  return showCreditsExhaustedSheet(context, reason: parsed);
}
