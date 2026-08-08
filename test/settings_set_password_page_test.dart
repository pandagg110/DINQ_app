import 'dart:async';

import 'package:dinq_app/pages/settings/settings_set_password_page.dart';
import 'package:dinq_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessfulAuthService extends AuthService {
  String? submittedCurrentPassword;
  String? submittedNewPassword;

  @override
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    submittedCurrentPassword = currentPassword;
    submittedNewPassword = newPassword;
  }
}

class _PopTrackingObserver extends NavigatorObserver {
  int popCount = 0;
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount += 1;
    super.didPop(route, previousRoute);
  }
}

void main() {
  Future<_PopTrackingObserver> openSuccessfulPasswordDialog(
    WidgetTester tester, {
    PasswordChangeSuccessCallback? onSuccess,
    bool hasPassword = false,
    _SuccessfulAuthService? authService,
  }) async {
    final observer = _PopTrackingObserver();
    final service = authService ?? _SuccessfulAuthService();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsSetPasswordPage(
                      hasPassword: hasPassword,
                      authService: service,
                      onSuccess: onSuccess,
                    ),
                  ),
                ),
                child: const Text('Open password page'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open password page'));
    await tester.pumpAndSettle();
    if (hasPassword) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter current password'),
        'current-password',
      );
    }
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter new password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm new password'),
      'password123',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Password set successfully'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(observer.pushCount, 2);
    return observer;
  }

  testWidgets('success confirmation closes the dialog and returns one page', (
    tester,
  ) async {
    await openSuccessfulPasswordDialog(tester);

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Password set successfully'), findsNothing);
    expect(find.text('Open password page'), findsOneWidget);
  });

  testWidgets('success is shown without waiting for profile refresh', (
    tester,
  ) async {
    final refresh = Completer<void>();

    await openSuccessfulPasswordDialog(tester, onSuccess: () => refresh.future);

    expect(find.text('Password set successfully'), findsOneWidget);
    refresh.complete();
  });

  testWidgets(
    'changing an existing password dismisses the keyboard before success',
    (tester) async {
      final service = _SuccessfulAuthService();

      await openSuccessfulPasswordDialog(
        tester,
        hasPassword: true,
        authService: service,
      );

      expect(service.submittedCurrentPassword, 'current-password');
      expect(service.submittedNewPassword, 'password123');
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('Password set successfully'), findsOneWidget);
    },
  );

  testWidgets('confirmation does not leave a modal route above settings', (
    tester,
  ) async {
    final observer = await openSuccessfulPasswordDialog(tester);

    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(observer.popCount, 1);

    await tester.pumpAndSettle();

    expect(observer.popCount, 1);
    expect(find.text('Password set successfully'), findsNothing);
    expect(find.text('Open password page'), findsOneWidget);
  });

  testWidgets('rapid confirmation taps cannot pop more than one page', (
    tester,
  ) async {
    final observer = await openSuccessfulPasswordDialog(tester);

    final okButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Ok'),
    );
    okButton.onPressed!.call();
    okButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(observer.popCount, 1);
    expect(find.text('Password set successfully'), findsNothing);
    expect(find.text('Open password page'), findsOneWidget);
  });

  testWidgets('confirmation clears its overlay when the page cannot pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsSetPasswordPage(
          hasPassword: false,
          authService: _SuccessfulAuthService(),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter new password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm new password'),
      'password123',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Password set successfully'), findsOneWidget);

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Password set successfully'), findsNothing);
    expect(find.text('Confirm'), findsOneWidget);
  });
}
