import 'package:dinq_app/widgets/app_update/update_required_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _panel({required List<String> notes}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 520,
        child: Center(
          child: UpdateRequiredPanel(releaseNotes: notes, onUpdateNow: () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('release notes use 18px line height and 4px paragraph spacing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _panel(notes: const ['First change', 'Second change']),
    );

    final first = tester.widget<Text>(
      find.byKey(const ValueKey('update-release-note-0')),
    );
    final gap = tester.widget<SizedBox>(
      find.byKey(const ValueKey('update-release-note-gap-1')),
    );

    expect(first.style?.fontSize, 12);
    expect(first.style?.height, 18 / 12);
    expect(gap.height, 4);
  });

  testWidgets('long release notes scroll without moving the update button', (
    tester,
  ) async {
    final notes = List<String>.generate(
      24,
      (index) => 'Release note ${index + 1} with enough text to wrap.',
    );
    await tester.pumpWidget(_panel(notes: notes));

    final scroll = find.byKey(const ValueKey('update-release-notes-scroll'));
    final button = find.text('Update');
    expect(scroll, findsOneWidget);
    expect(button, findsOneWidget);

    final buttonTopBefore = tester.getTopLeft(button).dy;
    await tester.drag(scroll, const Offset(0, -160));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(button).dy, buttonTopBefore);
    expect(
      find.text('24. Release note 24 with enough text to wrap.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
