import 'package:dinq_app/widgets/app_update/update_required_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _panel({required List<String> notes, double height = 520}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: height,
        child: Center(
          child: UpdateRequiredPanel(releaseNotes: notes, onUpdateNow: () {}),
        ),
      ),
    ),
  );
}

void main() {
  test('release notes preserve the backend text without renumbering', () {
    const raw = '''Version:1.0.1
1.Added smart search examples
2.Added social profile cards
- Existing bullet''';

    expect(UpdateRequiredPanel.parseReleaseNotes(raw), const [
      'Version:1.0.1',
      '1.Added smart search examples',
      '2.Added social profile cards',
      '- Existing bullet',
    ]);
  });

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
    expect(first.style?.color, const Color(0xFF575757));
    expect(first.data, 'First change');
    expect(gap.height, 4);
  });

  testWidgets('update panel is capped at 420px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notes = List<String>.generate(
      60,
      (index) => 'Backend release note ${index + 1}',
    );

    await tester.pumpWidget(_panel(notes: notes, height: 900));

    final panel = find.byKey(const ValueKey('update-required-panel'));
    final scroll = find.byKey(const ValueKey('update-release-notes-scroll'));
    expect(tester.getSize(panel).height, 420);
    expect(tester.getSize(scroll).height, lessThan(420));
    expect(tester.takeException(), isNull);
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
      find.text('Release note 24 with enough text to wrap.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
