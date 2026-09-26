import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/services/app_state.dart';

import 'test_helpers.dart';

void main() {
  test('Standardwerte beim ersten Start', () async {
    final s = await testState();
    expect(s.favorites, isEmpty);
    expect(s.notificationsEnabled, isTrue);
    expect(s.permissionAsked, isFalse);
    expect(s.onboardingDone, isFalse);
    expect(s.multiPerDay, isFalse);
    expect((s.dailyHour, s.dailyMinute), (8, 0));
    expect(s.themeMode, ThemeMode.system);
    expect(s.textScale, 1.0);
  });

  test('Favoriten bleiben nach einem Neustart erhalten', () async {
    final s = await testState();
    await s.toggleFavorite(3);
    await s.toggleFavorite(7);
    await s.toggleFavorite(3);

    final reloaded = await AppState.load();
    expect(reloaded.favorites, {7});
  });

  test('Einstellungen bleiben nach einem Neustart erhalten', () async {
    final s = await testState();
    await s.setDailyTime(6, 45);
    await s.setMultiPerDay(true);
    await s.setProWindow(startHour: 9, endHour: 18, interval: 3);
    await s.setThemeMode(ThemeMode.dark);
    await s.setTextScale(1.3);
    await s.setOnboardingDone();

    final r = await AppState.load();
    expect((r.dailyHour, r.dailyMinute), (6, 45));
    expect(r.multiPerDay, isTrue);
    expect((r.proStartHour, r.proEndHour, r.proIntervalHours), (9, 18, 3));
    expect(r.themeMode, ThemeMode.dark);
    expect(r.textScale, 1.3);
    expect(r.onboardingDone, isTrue);
  });

  test('Zeitfenster: Ende nie vor dem Anfang', () async {
    final s = await testState();
    await s.setProWindow(startHour: 20, endHour: 10);
    expect(s.proEndHour, 20);
  });

  test('Zeitplan-Änderungen lösen ein Neuplanen aus', () async {
    final s = await testState();
    var calls = 0;
    s.onScheduleChanged = () => calls++;
    await s.setDailyTime(7, 0);
    await s.setMultiPerDay(true);
    await s.setNotificationsEnabled(false);
    await s.setProWindow(interval: 2);
    await s.toggleFavorite(1); // kein Einfluss auf den Zeitplan
    await s.setThemeMode(ThemeMode.light);
    expect(calls, 4);
  });

  test('Erster Start wird einmal gespeichert', () async {
    final s = await testState();
    final first = s.firstLaunch;
    final r = await AppState.load();
    expect(r.firstLaunch, first);
  });
}
