import 'package:dinq_app/pages/settings/settings_set_password_page.dart';
import 'package:dinq_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessfulAuthService extends AuthService {
  @override
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {}
}

void main() {
  Future<void> openSuccessfulPasswordDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsSetPasswordPage(
                      hasPassword: false,
                      authService: _SuccessfulAuthService(),
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

  testWidgets('rapid confirmation taps cannot pop more than one page', (
    tester,
  ) async {
    await openSuccessfulPasswordDialog(tester);

    final okButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Ok'),
    );
    okButton.onPressed!.call();
    okButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Password set successfully'), findsNothing);
    expect(find.text('Open password page'), findsOneWidget);
  });
}
