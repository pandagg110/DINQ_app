import 'package:dinq_app/pages/settings/settings_help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('version row does not show a right chevron', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsHelpPage()));
    await tester.pump();

    expect(find.text('Version'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(4));
    final versionTapTarget = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('Version'),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(versionTapTarget.onTap, isNull);
  });
}
