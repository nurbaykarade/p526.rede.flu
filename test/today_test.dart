import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Heute zeigt die letzten Tage und den ganzen Verlauf', (
    tester,
  ) async {
    final since = DateTime.now().subtract(const Duration(days: 10));
    final state = await testState({
      'permissionAsked': true,
      'firstLaunch': since.toIso8601String(),
    });
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Die letzten Tage'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ganzer Verlauf'), 200);
    await tester.tap(find.text('Ganzer Verlauf'));
    await tester.pumpAndSettle();

    expect(find.text('Verlauf'), findsOneWidget);
    expect(find.textContaining('Gestern'), findsOneWidget);
  });

  testWidgets('Am ersten Tag gibt es noch keinen Verlauf', (tester) async {
    final state = await testState({'permissionAsked': true});
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('Die letzten Tage'), findsNothing);
  });
}
