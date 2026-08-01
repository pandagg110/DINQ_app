import 'package:dinq_app/stores/user_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'post-login failures do not turn a successful OAuth response into an error',
    () async {
      final calls = <String>[];

      await runPostLoginTasks([
        () async {
          calls.add('persist');
          throw StateError('disk unavailable');
        },
        () async {
          calls.add('initialize');
          throw StateError('profile unavailable');
        },
        () async => calls.add('analytics'),
      ]);

      expect(calls, ['persist', 'initialize', 'analytics']);
    },
  );
}
