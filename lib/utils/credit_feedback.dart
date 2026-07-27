import 'dart:async';

import 'package:dio/dio.dart';

import '../stores/user_store.dart';

const _creditRefreshRetryMs = 1000;

/// 与 TSX SearchPanel / useDeepSearch isInsufficientCredits 一致。
bool isInsufficientCredits(String message) {
  return RegExp(
    r'insufficient\s+credits',
    caseSensitive: false,
  ).hasMatch(message);
}

/// 对齐 Web `EnrichProfileView.tsx` isInsufficientCreditsError。
bool isInsufficientCreditsError(Object? error) {
  if (error == null) return false;

  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final code = data['code'];
      if (code == 3001 || code == '3001') return true;
      final message = data['message']?.toString();
      if (message != null && isInsufficientCredits(message)) return true;
    }
    final message = error.message;
    if (message != null && isInsufficientCredits(message)) return true;
  }

  var message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    message = message.substring('Exception: '.length).trim();
  }
  return isInsufficientCredits(message);
}

/// 对齐 Web `refreshCreditsAfterMutation`。
void refreshCreditsAfterMutation(UserStore userStore) {
  unawaited(userStore.refreshSubscription());
  Future<void>.delayed(
    const Duration(milliseconds: _creditRefreshRetryMs),
    () => userStore.refreshSubscription(),
  );
}
