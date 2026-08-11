import 'package:dinq_app/widgets/subscription/subscription_managed_elsewhere_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a blocking modal and closes only from OK', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSubscriptionManagedElsewhereDialog(
                context,
                subscriptionChannel: 'stripe',
              ),
              child: const Text('Upgrade'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.byKey(const Key('subscription-managed-elsewhere-dialog')),
      findsOneWidget,
    );
    expect(
      find.textContaining('purchased on another platform'),
      findsOneWidget,
    );
    expect(find.textContaining('dinq.me'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('subscription-managed-elsewhere-dialog')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('subscription-managed-elsewhere-dialog')),
      findsOneWidget,
    );

    expect(
      tester
          .getSize(find.byKey(const Key('subscription-managed-elsewhere-ok')))
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('subscription-managed-elsewhere-dialog')),
      findsNothing,
    );
  });

  testWidgets('names Google Play as the original purchase channel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSubscriptionManagedElsewhereDialog(
                context,
                subscriptionChannel: 'google_play',
              ),
              child: const Text('Upgrade'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Google Play'), findsWidgets);
  });
}
