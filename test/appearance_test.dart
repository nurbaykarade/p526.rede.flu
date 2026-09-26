import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/services/app_state.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Dunkles Design wird übernommen und gespeichert', (tester) async {
    final state = await testState({'permissionAsked': true});
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();

    await state.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect((await AppState.load()).themeMode, ThemeMode.dark);
  });

  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('Sehr große Schrift ohne Überlauf (${size.width.toInt()} px)', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = await testState({
        'permissionAsked': true,
        'textScale': 1.3,
      });
      await tester.pumpWidget(testApp(state: state));
      await tester.pumpAndSettle();

      for (final tab in ['Alle', 'Favoriten', 'Einstellungen', 'Heute']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
