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

AppUpdateInfo _update(AppUpdateType type, {String? releaseNotes}) =>
    AppUpdateInfo(
      platform: 'android',
      channel: 'official_apk',
      updateType: type,
      latestVersion: '0.1.2',
      latestVersionCode: 7,
      minimumVersion: '0.1.1',
      minimumVersionCode: 6,
      releaseNotes: releaseNotes ?? 'Critical fixes',
      downloadUrl: 'https://dinq.me/download/android',
    );

void main() {
  testWidgets('forced update blocks the app and cannot be skipped', (
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

    expect(find.text('New Version Available'), findsOneWidget);
    expect(find.text('1. Critical fixes'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('App content'), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
  });

  testWidgets('none renders app content without an update barrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateGate(
          checker: _FakeChecker(_update(AppUpdateType.none)),
          openUpdate: (_) async => true,
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App content'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ModalBarrier && widget.color == const Color(0x99000000),
      ),
      findsNothing,
    );
    expect(find.text('New Version Available'), findsNothing);
  });

  testWidgets('optional update can be skipped', (tester) async {
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

    expect(find.text('New Version Available'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('New Version Available'), findsNothing);
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

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to open the update page. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('Update opens the URL returned by the version endpoint', (
    tester,
  ) async {
    String? openedUrl;
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateGate(
          checker: _FakeChecker(_update(AppUpdateType.force)),
          openUpdate: (url) async {
            openedUrl = url;
            return true;
          },
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(openedUrl, 'https://dinq.me/download/android');
  });
}
