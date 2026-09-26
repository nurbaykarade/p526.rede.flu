/// Reine Berechnung der Benachrichtigungszeiten – ohne Plugin-Abhängigkeit,
/// damit sie leicht getestet werden kann.
class ScheduleSlot {
  const ScheduleSlot(this.time, this.slot);

  /// Lokale Uhrzeit, zu der die Benachrichtigung erscheinen soll.
  final DateTime time;

  /// Index innerhalb des Tages (0 = Redewendung des Tages).
  final int slot;

  @override
  String toString() => 'ScheduleSlot($time, $slot)';
}

/// iOS erlaubt maximal 64 ausstehende Benachrichtigungen.
/// 1 Platz bleibt für die „App öffnen“-Erinnerung frei.
const int kMaxScheduled = 60;

List<ScheduleSlot> computeSchedule({
  required DateTime now,
  required bool multiPerDay,
  required int dailyHour,
  required int dailyMinute,
  required int proStartHour,
  required int proEndHour,
  required int proIntervalHours,
  int maxDays = 30,
  int maxCount = kMaxScheduled,
}) {
  final result = <ScheduleSlot>[];
  for (var d = 0; d <= maxDays && result.length < maxCount; d++) {
    if (!multiPerDay) {
      final t = DateTime(now.year, now.month, now.day + d, dailyHour, dailyMinute);
      if (t.isAfter(now)) result.add(ScheduleSlot(t, 0));
      continue;
    }
    final int interval = proIntervalHours < 1 ? 1 : proIntervalHours;
    var slot = 0;
    for (var h = proStartHour; h <= proEndHour; h += interval) {
      final t = DateTime(now.year, now.month, now.day + d, h);
      if (t.isAfter(now)) {
        result.add(ScheduleSlot(t, slot));
        if (result.length >= maxCount) break;
      }
      slot++;
    }
  }
  return result;
}
