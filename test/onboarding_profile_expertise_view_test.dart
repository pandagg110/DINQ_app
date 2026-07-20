import 'package:dinq_app/widgets/generation/onboarding/onboarding_profile_expertise_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adds a custom tag with a rounded Add button', (tester) async {
    var tags = <String>[];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingProfileExpertiseView(
            tags: tags,
            bio: '',
            onTagsChanged: (nextTags) => tags = nextTags,
            onBioChanged: (_) {},
            previewName: '',
            previewPosition: '',
            previewCompany: '',
            previewSchool: '',
            previewLocation: '',
            previewTimezone: '',
            previewAvatarUrl: '',
            onBack: () {},
            onContinue: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Dart');
    await tester.pump();
    final addButton = find.widgetWithText(OutlinedButton, 'Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);

    expect(tags, ['Dart']);
    final button = tester.widget<OutlinedButton>(addButton);
    final shape = button.style?.shape?.resolve({});
    expect(shape, isA<RoundedRectangleBorder>());
  });
}
