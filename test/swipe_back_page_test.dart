import 'package:dinq_app/widgets/common/swipe_back_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('system back invokes onBack when enabled', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackPage(
          onBack: () => closed = true,
          child: const Scaffold(body: Text('detail')),
        ),
      ),
    );

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    expect(await widgetsAppState.didPopRoute(), isTrue);
    expect(closed, isTrue);
    expect(find.text('detail'), findsOneWidget);
  });

  testWidgets('shouldHandlePop false lets route pop through', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SwipeBackPage(
          onBack: () => closed = true,
          shouldHandlePop: () => false,
          child: const Scaffold(body: Text('detail')),
        ),
      ),
    );

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    // canPop is true → didPopRoute returns false (nothing consumed by PopScope)
    expect(await widgetsAppState.didPopRoute(), isFalse);
    expect(closed, isFalse);
  });
}
