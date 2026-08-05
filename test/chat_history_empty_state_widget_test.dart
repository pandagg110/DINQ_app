import 'package:dinq_app/widgets/search/history/chat_history_empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('network error shows friendly copy and retry', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatHistoryEmptyStateWidget(
            type: 'error',
            message: 'Network timeout. Please try again.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Network timeout. Please try again.'), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('generic error hides technical dio text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatHistoryEmptyStateWidget(
            type: 'error',
            message: 'Failed to load history',
          ),
        ),
      ),
    );

    expect(find.text('Failed to load history'), findsWidgets);
    expect(find.text('Retry'), findsNothing);
  });
}
