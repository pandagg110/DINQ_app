import 'package:dinq_app/services/store_cancellation_flow.dart';
import 'package:dinq_app/widgets/marketing/store_cancellation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('store cancellation copy', () {
    test('routes cancellation using the original subscription channel', () {
      expect(
        storeSubscriptionChannelFromApi('apple'),
        StoreSubscriptionChannel.apple,
      );
      expect(
        storeSubscriptionChannelFromApi('google_play'),
        StoreSubscriptionChannel.googlePlay,
      );
      expect(storeSubscriptionChannelFromApi('stripe'), isNull);
    });

    test('uses Apple-specific confirmation copy', () {
      final copy = storeCancellationCopy(
        channel: StoreSubscriptionChannel.apple,
        expirationDate: 'August 31, 2026',
      );

      expect(copy.title, 'Switch to Free?');
      expect(copy.description, contains('active until August 31, 2026'));
      expect(copy.description, contains('through Apple'));
      expect(copy.description, isNot(contains('not be charged again')));
      expect(copy.continueLabel, 'Continue to Apple');
    });

    test('uses Google Play-specific confirmation copy', () {
      final copy = storeCancellationCopy(
        channel: StoreSubscriptionChannel.googlePlay,
        expirationDate: 'August 31, 2026',
      );

      expect(copy.description, contains('in Google Play'));
      expect(copy.continueLabel, 'Continue to Google Play');
    });

    test('only confirms no further charge after backend confirmation', () {
      expect(
        confirmedStoreCancellationMessage(
          cancelAtPeriodEnd: false,
          expirationDate: 'August 31, 2026',
        ),
        isNull,
      );
      expect(
        confirmedStoreCancellationMessage(
          cancelAtPeriodEnd: true,
          expirationDate: 'August 31, 2026',
        ),
        'Your plan will remain active until August 31, 2026, then switch to '
        'the Free plan. You will not be charged again.',
      );
    });
  });

  test(
    'retries subscription refresh until cancellation is confirmed',
    () async {
      var refreshCount = 0;
      var confirmed = false;

      final result = await refreshUntilStoreCancellationConfirmed(
        refresh: () async {
          refreshCount++;
          if (refreshCount == 2) confirmed = true;
        },
        isConfirmed: () => confirmed,
        retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
        wait: (_) async {},
      );

      expect(result, isTrue);
      expect(refreshCount, 2);
    },
  );

  testWidgets('confirmation dialog requires an explicit store action', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoreCancellationDialog(
            copy: storeCancellationCopy(
              channel: StoreSubscriptionChannel.apple,
              expirationDate: 'August 31, 2026',
            ),
            onCancel: () {},
            onContinue: () => continued = true,
          ),
        ),
      ),
    );

    expect(find.text('Switch to Free?'), findsOneWidget);
    expect(find.text('Continue to Apple'), findsOneWidget);
    await tester.tap(find.text('Continue to Apple'));
    expect(continued, isTrue);
  });
}
