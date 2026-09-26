import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Onboarding: Weiter, Erlauben, danach die App', (tester) async {
    final state = await testState();
    final notifications = FakeNotificationService();
    await tester.pumpWidget(
      testApp(state: state, notifications: notifications),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei Redewendix'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Direkt auf dem Sperrbildschirm'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Mitteilungen erlauben'),
    );
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(state.permissionAsked, isTrue);
    expect(state.onboardingDone, isTrue);
    expect(find.text('Redewendung des Tages'), findsOneWidget);
  });

  testWidgets('Onboarding: Später fragt nicht nach der Erlaubnis', (
    tester,
  ) async {
    final state = await testState();
    final notifications = FakeNotificationService();
    await tester.pumpWidget(
      testApp(state: state, notifications: notifications),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Später'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 0);
    expect(state.onboardingDone, isTrue);
    expect(state.permissionAsked, isFalse);
    // Heute-Tab bietet die Erlaubnis weiterhin an.
    expect(find.text('Mitteilungen erlauben'), findsOneWidget);
  });

  testWidgets('Bestehende Nutzer sehen kein Onboarding', (tester) async {
    final state = await testState({'permissionAsked': true});
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei Redewendix'), findsNothing);
    expect(find.text('Redewendung des Tages'), findsOneWidget);
  });

  testWidgets('Onboarding mit sehr großer Schrift auf 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = await testState({'textScale': 1.3});
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
