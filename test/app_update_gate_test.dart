import 'package:dinq_app/services/app_update_service.dart';
import 'package:dinq_app/widgets/app_update/app_update_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChecker implements AppUpdateChecker {
  _FakeChecker(this.info);

  final AppUpdateInfo? info;

  @override
  Future<AppUpdateInfo?> check() async => info;
}

AppUpdateInfo _update(AppUpdateType type) => AppUpdateInfo(
  platform: 'android',
  channel: 'official_apk',
  updateType: type,
  latestVersion: '0.1.2',
  latestVersionCode: 7,
  minimumVersion: '0.1.1',
  minimumVersionCode: 6,
  releaseNotes: 'Critical fixes',
  downloadUrl: 'https://dinq.me/download/android',
);

void main() {
  testWidgets('forced update blocks the app and cannot be dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateGate(
          checker: _FakeChecker(_update(AppUpdateType.force)),
          openUpdate: (_) async => true,
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('0.1.2'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
    expect(find.text('App content'), findsOneWidget);
  });

  testWidgets('optional update can be dismissed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateGate(
          checker: _FakeChecker(_update(AppUpdateType.optional)),
          openUpdate: (_) async => true,
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update Required'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Update Required'), findsNothing);
    expect(find.text('App content'), findsOneWidget);
  });

  testWidgets('failed update link keeps the forced gate usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateGate(
          checker: _FakeChecker(_update(AppUpdateType.force)),
          openUpdate: (_) => throw StateError('cannot launch'),
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to open the update page. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Update Now'), findsOneWidget);
  });
}
