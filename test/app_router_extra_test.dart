import 'package:dinq_app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password route tolerates missing extra after router refresh', () {
    final args = AppRouter.passwordRouteArgs(null);

    expect(args.hasPassword, isFalse);
    expect(args.onSuccess, isNull);
  });

  test('password route preserves supplied arguments', () {
    Future<void> onSuccess() async {}

    final args = AppRouter.passwordRouteArgs({
      'hasPassword': true,
      'onSuccess': onSuccess,
    });

    expect(args.hasPassword, isTrue);
    expect(args.onSuccess, same(onSuccess));
  });

  test('email route tolerates missing extra after router refresh', () {
    final args = AppRouter.emailRouteArgs(null);

    expect(args.currentEmail, isNull);
    expect(args.onSuccess, isNull);
  });

  test('email route preserves supplied arguments', () {
    var refreshCount = 0;
    void onSuccess() => refreshCount += 1;

    final args = AppRouter.emailRouteArgs({
      'currentEmail': 'user@example.com',
      'onSuccess': onSuccess,
    });

    expect(args.currentEmail, 'user@example.com');
    args.onSuccess?.call();
    expect(refreshCount, 1);
  });
}
