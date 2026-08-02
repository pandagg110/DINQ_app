import 'package:dinq_app/widgets/marketing/contact_support_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('contact support asks for confirmation before opening email', (
    tester,
  ) async {
    var contacted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContactSupportDialog(onContact: () => contacted = true),
        ),
      ),
    );

    expect(find.text('Contact support'), findsWidgets);
    expect(find.textContaining('support@dinqlabs.com'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Email support'));
    expect(contacted, isTrue);
  });
}
