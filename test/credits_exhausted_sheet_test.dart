import 'package:dinq_app/stores/user_store.dart';
import 'package:dinq_app/widgets/credits/credits_exhausted_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sheet background covers the bottom safe area', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final userStore = UserStore();
    await userStore.ready;
    addTearDown(userStore.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: userStore,
        child: const MaterialApp(
          home: Scaffold(
            body: CreditsExhaustedSheet(reason: CreditsExhaustedReason.search),
          ),
        ),
      ),
    );

    final safeArea = find.descendant(
      of: find.byType(CreditsExhaustedSheet),
      matching: find.byType(SafeArea),
    );
    final sheetBackground = find.ancestor(
      of: safeArea,
      matching: find.byWidgetPredicate((widget) {
        final decoration = widget is Container ? widget.decoration : null;
        return decoration is BoxDecoration &&
            decoration.color == const Color(0xFFFCFBF9);
      }),
    );

    expect(safeArea, findsOneWidget);
    expect(sheetBackground, findsOneWidget);
  });
}
