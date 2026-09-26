import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/models/idiom.dart';
import 'package:redewendix/services/idiom_repository.dart';

void main() {
  final repo = IdiomRepository(const [
    Idiom(
      id: 1,
      text: 'Über den Berg sein',
      meaning: 'Das Schlimmste überstanden haben.',
      origin: '',
      example: '',
    ),
    Idiom(
      id: 2,
      text: 'Tomaten auf den Augen haben',
      meaning: 'Etwas Offensichtliches nicht sehen.',
      origin: '',
      example: '',
    ),
    Idiom(
      id: 3,
      text: 'Den Nagel auf den Kopf treffen',
      meaning: 'Genau das Richtige sagen; über etwas Wichtiges sprechen.',
      origin: '',
      example: '',
    ),
  ]);

  group('search', () {
    test('leere Anfrage liefert alle, alphabetisch', () {
      expect(repo.search('  ').map((i) => i.id), [3, 2, 1]);
    });

    test('Umlaute dürfen umschrieben werden', () {
      for (final q in ['über', 'ueber', 'uber', 'ÜBER']) {
        expect(repo.search(q).first.id, 1, reason: q);
      }
    });

    test('Treffer in der Redewendung vor Treffern in der Bedeutung', () {
      expect(repo.search('über').map((i) => i.id), [1, 3]);
    });

    test('alle Wörter müssen vorkommen, Reihenfolge egal', () {
      expect(repo.search('augen tomaten').map((i) => i.id), [2]);
      expect(repo.search('augen kopf'), isEmpty);
    });

    test('Satzzeichen werden ignoriert', () {
      expect(repo.search('„nagel“').map((i) => i.id), [3]);
    });
  });

  group('history', () {
    final today = DateTime(2026, 9, 27, 10);

    test('neueste zuerst, ohne heute', () {
      final h = repo.history(today, since: DateTime(2026, 9, 20));
      expect(h.first.day, DateTime(2026, 9, 26));
      expect(h.last.day, DateTime(2026, 9, 20));
      expect(h.length, 7);
      expect(h.first.idiom.id, repo.forDay(DateTime(2026, 9, 26)).id);
    });

    test('nichts vor dem ersten Start', () {
      expect(repo.history(today, since: DateTime(2026, 9, 27, 8)), isEmpty);
    });

    test('höchstens maxDays', () {
      final h = repo.history(today, since: DateTime(2025), maxDays: 30);
      expect(h.length, 30);
    });
  });
}
