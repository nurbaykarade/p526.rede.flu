const _weekdays = [
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
];

const _months = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

/// z. B. „Samstag, 26. September 2026“
String formatGermanDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day}. ${_months[d.month - 1]} ${d.year}';

/// z. B. „08:00“
String formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

const _shortWeekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// z. B. „Sa, 26.09.“
String formatShortGermanDate(DateTime d) =>
    '${_shortWeekdays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.';

/// „Gestern“, „Vorgestern“ oder das kurze Datum.
String formatPastDay(DateTime d, DateTime today) {
  final diff = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(d.year, d.month, d.day))
      .inDays;
  if (diff == 1) return 'Gestern';
  if (diff == 2) return 'Vorgestern';
  return formatShortGermanDate(d);
}
