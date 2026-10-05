import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/design/components/tutor_avatar_widget.dart';
import 'package:talkloom_flutter/design/theme.dart';

void main() {
  testWidgets('TutorAvatarWidget renders all 4 conversational states properly', (tester) async {
    for (final state in TutorAvatarState.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTalkloomTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: TutorAvatarWidget(
                state: state,
                personaName: 'Test Tutor',
                personaRole: 'Pedagogical Partner',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Tutor'), findsOneWidget);
      expect(find.text('Pedagogical Partner'), findsOneWidget);
      expect(find.byType(TutorAvatarWidget), findsOneWidget);
    }
  });
}
