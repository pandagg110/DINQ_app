import 'dart:async';

import 'package:flutter/foundation.dart';

/// Keeps authentication failures separate from work performed after the
/// server has already accepted the login. A navigation or UI cleanup failure
/// must never be presented as an OAuth credential failure.
Future<bool> runOAuthLoginAttempt({
  required Future<bool> Function() authenticate,
  required FutureOr<void> Function() onAuthenticated,
  required FutureOr<void> Function(Object error) onAuthenticationFailed,
}) async {
  final result = await runLoginAttempt<bool>(
    authenticate: authenticate,
    onAuthenticated: onAuthenticated,
    onAuthenticationFailed: onAuthenticationFailed,
  );
  return result ?? false;
}

/// Keeps a successful password/token exchange separate from cleanup,
/// initialization and navigation work performed afterwards.
Future<bool?> runLoginAttempt<T>({
  required Future<T> Function() authenticate,
  required FutureOr<void> Function() onAuthenticated,
  required FutureOr<void> Function(Object error) onAuthenticationFailed,
}) async {
  final T authenticated;
  try {
    authenticated = await authenticate();
  } catch (error) {
    await onAuthenticationFailed(error);
    return null;
  }

  if (authenticated is bool && !authenticated) return false;

  try {
    await onAuthenticated();
  } catch (error) {
    // Do not log tokens, provider responses, or stack traces.
    debugPrint('Post-login action failed: ${error.runtimeType}');
  }
  return true;
}
