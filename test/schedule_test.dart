import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/models/idiom.dart';
import 'package:redewendix/services/idiom_repository.dart';
import 'package:redewendix/services/schedule.dart';

void main() {
  group('computeSchedule', () {
    test('Einmal täglich: einmal täglich, nur zukünftige Zeiten', () {
      final now = DateTime(2026, 9, 26, 9, 0);
      final s = computeSchedule(
        now: now,
        multiPerDay: false,
        dailyHour: 8,
        dailyMinute: 0,
        proStartHour: 8,
        proEndHour: 20,
        proIntervalHours: 1,
      );
      expect(s.first.time, DateTime(2026, 9, 27, 8));
      expect(s.every((e) => e.slot == 0), isTrue);
      expect(s.length, 30);
    });

    test('Mehrmals täglich: stündlich im Zeitfenster, max. $kMaxScheduled', () {
      final now = DateTime(2026, 9, 26, 7, 30);
      final s = computeSchedule(
        now: now,
        multiPerDay: true,
        dailyHour: 8,
        dailyMinute: 0,
        proStartHour: 8,
        proEndHour: 20,
        proIntervalHours: 1,
      );
      expect(s.length, kMaxScheduled);
      expect(s.first.time, DateTime(2026, 9, 26, 8));
      expect(s[12].time, DateTime(2026, 9, 26, 20));
      expect(s[13].time, DateTime(2026, 9, 27, 8));
      expect(s[13].slot, 0);
    });

    test('Mehrmals täglich: Intervall 3 Stunden', () {
      final now = DateTime(2026, 9, 26, 0, 0);
      final s = computeSchedule(
        now: now,
        multiPerDay: true,
        dailyHour: 8,
        dailyMinute: 0,
        proStartHour: 9,
        proEndHour: 18,
        proIntervalHours: 3,
      );
      expect(s.take(4).map((e) => e.time.hour), [9, 12, 15, 18]);
    });
  });

  test('Redewendung des Tages wechselt täglich und ist stabil', () {
    final repo = IdiomRepository([
      for (var i = 1; i <= 10; i++)
        Idiom(id: i, text: 'R$i', meaning: '', origin: '', example: ''),
    ]);
    final a = repo.forDay(DateTime(2026, 9, 26, 8));
    final b = repo.forDay(DateTime(2026, 9, 26, 22));
    final c = repo.forDay(DateTime(2026, 9, 27, 8));
    expect(a.id, b.id);
    expect(a.id, isNot(c.id));
    expect(repo.forSlot(DateTime(2026, 9, 26), 0).id, a.id);
    expect(repo.forSlot(DateTime(2026, 9, 26), 1).id, isNot(a.id));
  });
}
