import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/services/widget_service.dart';

import 'test_helpers.dart';

void main() {
  test('widgetDays: heute und die nächsten 30 Tage, passend zur App', () {
    final repo = testRepo();
    final now = DateTime(2026, 12, 30, 23, 30);
    final days = widgetDays(repo, now);

    expect(days.length, kWidgetDays + 1);
    expect(days.keys.first, '2026-12-30');
    expect(days.keys.elementAt(2), '2027-01-01');
    final jan1 = days['2027-01-01']!;
    final expected = repo.forDay(DateTime(2027, 1, 1));
    expect(jan1['id'], expected.id);
    expect(jan1['text'], expected.text);
    expect(jan1['meaning'], expected.meaning);
  });

  test('widgetDays über die Zeitumstellung', () {
    // 25. Oktober 2026: Ende der Sommerzeit in Deutschland.
    final days = widgetDays(testRepo(), DateTime(2026, 10, 24, 12));
    expect(days.keys.take(3), ['2026-10-24', '2026-10-25', '2026-10-26']);
  });

  test('idiomIdFromUri', () {
    expect(idiomIdFromUri(Uri.parse('redewendix://idiom/42')), 42);
    expect(idiomIdFromUri(Uri.parse('redewendix://idiom/42?homeWidget')), 42);
    expect(idiomIdFromUri(Uri.parse('redewendix://idiom/')), isNull);
    expect(idiomIdFromUri(Uri.parse('redewendix://other/1')), isNull);
    expect(idiomIdFromUri(null), isNull);
  });
}
