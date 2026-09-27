import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/models/idiom.dart';
import 'package:redewendix/services/idiom_repository.dart';

/// Prüft die echten Redewendungen in assets/idioms.json.
void main() {
  final idioms =
      (jsonDecode(File('assets/idioms.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>()
          .map(Idiom.fromJson)
          .toList();
  final repo = IdiomRepository(idioms);
  final packs = [
    for (final file
        in (jsonDecode(File('assets/packs/index.json').readAsStringSync())
                as List)
            .cast<String>())
      IdiomPack.fromJson(
        jsonDecode(File('assets/packs/$file').readAsStringSync())
            as Map<String, dynamic>,
      ),
  ];
  final everything = [...idioms, for (final p in packs) ...p.idioms];

  test('IDs sind eindeutig und fortlaufend ab 1', () {
    expect(idioms.map((i) => i.id), [
      for (var i = 1; i <= idioms.length; i++) i,
    ]);
  });

  test('Keine doppelten Redewendungen', () {
    final seen = <String>{};
    for (final i in idioms) {
      expect(
        seen.add(IdiomRepository.normalize(i.text)),
        isTrue,
        reason: 'doppelt: ${i.text}',
      );
    }
  });

  test('Alle Felder sind ausgefüllt und nicht zu lang', () {
    for (final i in idioms) {
      expect(i.text.trim(), isNotEmpty);
      expect(i.meaning.trim(), isNotEmpty, reason: i.text);
      expect(i.origin.trim(), isNotEmpty, reason: i.text);
      expect(i.example.trim(), isNotEmpty, reason: i.text);
      expect(i.text.length, lessThanOrEqualTo(60), reason: i.text);
      expect(i.meaning.length, lessThanOrEqualTo(120), reason: i.text);
      expect(i.origin.length, lessThanOrEqualTo(260), reason: i.text);
      expect(i.example.length, lessThanOrEqualTo(160), reason: i.text);
      expect(i.text, isNot(contains('"')), reason: i.text);
    }
  });

  test('Ein ganzer Durchlauf ohne Wiederholung', () {
    final start = DateTime(2026, 9, 27);
    final ids = {
      for (var d = 0; d < idioms.length; d++)
        repo.forDay(DateTime(start.year, start.month, start.day + d)).id,
    };
    expect(ids.length, idioms.length);
  });

  test('Zusätzliche Mitteilungen wiederholen sich an einem Tag nicht', () {
    final day = DateTime(2026, 9, 27);
    final ids = [for (var s = 0; s < 16; s++) repo.forSlot(day, s).id];
    expect(ids.toSet().length, ids.length);
  });

  test('Pakete: IDs eindeutig über alles, eigener Bereich je Paket', () {
    final ids = everything.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final (n, p) in packs.indexed) {
      expect(p.idioms, isNotEmpty, reason: p.id);
      expect(p.title.trim(), isNotEmpty);
      expect(p.description.trim(), isNotEmpty);
      for (final i in p.idioms) {
        expect(
          i.id,
          inInclusiveRange((n + 1) * 1000 + 1, (n + 1) * 1000 + 999),
          reason: '${p.id}: ${i.text}',
        );
      }
    }
  });

  test('Pakete: keine Dubletten, Felder ausgefüllt', () {
    final seen = <String>{};
    for (final i in everything) {
      expect(
        seen.add(IdiomRepository.normalize(i.text)),
        isTrue,
        reason: 'doppelt: ${i.text}',
      );
      expect(i.meaning.trim(), isNotEmpty, reason: i.text);
      expect(i.origin.trim(), isNotEmpty, reason: i.text);
      expect(i.example.trim(), isNotEmpty, reason: i.text);
      expect(i.text.length, lessThanOrEqualTo(70), reason: i.text);
      expect(i.origin.length, lessThanOrEqualTo(260), reason: i.text);
    }
  });
}
