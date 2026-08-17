import 'dart:async';

import 'package:flutter/foundation.dart';

/// Prevents the same interactive OAuth flow from being started twice.
///
/// Native providers such as Apple reject overlapping authorization requests,
/// so rapid taps must be ignored until the active attempt has completed.
final class OAuthLoginAttemptGuard {
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<bool> run(Future<void> Function() attempt) async {
    if (_isRunning) return false;
    _isRunning = true;
    try {
      await attempt();
      return true;
    } finally {
      _isRunning = false;
    }
  }
}

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
