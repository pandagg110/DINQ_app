import 'package:dinq_app/widgets/search/enrich/enrich_contact_email_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps email composer actions outside the scrollable content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 720,
            child: EnrichContactEmailModal(
              recipientEmail: 'recipient@example.com',
              recipientName: 'Recipient',
              loadInitialData: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('email-composer-actions')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('email-composer-actions')),
        matching: find.text('Cancel'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('email-composer-actions')),
        matching: find.text('Send'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byKey(const Key('email-composer-actions')),
      ),
      findsNothing,
    );
  });
}
