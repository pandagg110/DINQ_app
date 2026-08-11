import 'package:dinq_app/pages/marketing/pricing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('savings label aligns vertically with the plan title', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: SubscriptionPlanHeader(
                title: 'Basic',
                subtitle: 'Individual Users / Beginners',
                savingsLabel: r'You save US$88.01/year',
              ),
            ),
          ),
        ),
      ),
    );

    final titleRect = tester.getRect(find.text('Basic'));
    final savingsRect = tester.getRect(find.text(r'You save US$88.01/year'));
    final subtitleRect = tester.getRect(
      find.text('Individual Users / Beginners'),
    );

    expect((titleRect.center.dy - savingsRect.center.dy).abs(), lessThan(1));
    expect(subtitleRect.top, greaterThan(titleRect.bottom));
  });
}
