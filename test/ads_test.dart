import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/services/ad_service.dart';
import 'package:redewendix/widgets/ad_banner.dart';

import 'test_helpers.dart';

void main() {
  group('Vollbild-Anzeige', () {
    final first = DateTime(2026, 10, 1, 9);
    final nextDay = DateTime(2026, 10, 2, 12);

    bool show({DateTime? now, int opens = 3, bool shown = false}) =>
        shouldShowInterstitial(
          now: now ?? nextDay,
          firstLaunch: first,
          opensToday: opens,
          shownToday: shown,
        );

    test('nie am ersten Tag', () {
      expect(show(now: DateTime(2026, 10, 1, 23), opens: 10), isFalse);
    });

    test('erst ab der dritten Redewendung am Tag', () {
      expect(show(opens: 2), isFalse);
      expect(show(opens: 3), isTrue);
    });

    test('höchstens einmal pro Tag', () {
      expect(show(opens: 5, shown: true), isFalse);
    });
  });

  test('Zähler beginnen jeden Tag neu', () async {
    final s = await testState();
    final day1 = DateTime(2026, 10, 2, 10);
    final day2 = DateTime(2026, 10, 3, 10);
    await s.countDetailOpen(day1);
    await s.countDetailOpen(day1);
    await s.markInterstitialShown(day1);
    expect(s.detailOpensToday(day1), 2);
    expect(s.interstitialShownToday(day1), isTrue);
    expect(s.detailOpensToday(day2), 0);
    expect(s.interstitialShownToday(day2), isFalse);
    await s.countDetailOpen(day2);
    expect(s.detailOpensToday(day2), 1);
    expect(s.interstitialShownToday(day2), isFalse);
  });

  testWidgets('Detailseite aus der App zählt; ohne Anzeigen kein Banner', (
    tester,
  ) async {
    final state = await testState({'permissionAsked': true});
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mehr erfahren'));
    await tester.pumpAndSettle();
    expect(find.byType(AdBanner), findsOneWidget);
    expect(tester.getSize(find.byType(AdBanner)).height, 0);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(state.detailOpensToday(DateTime.now()), 1);
  });
}
