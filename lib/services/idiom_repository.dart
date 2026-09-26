import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/idiom.dart';

class IdiomRepository {
  IdiomRepository(this._idioms) : _byId = {for (final i in _idioms) i.id: i};

  final List<Idiom> _idioms;
  final Map<int, Idiom> _byId;

  static Future<IdiomRepository> load() async {
    final raw = await rootBundle.loadString('assets/idioms.json');
    final list = (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(Idiom.fromJson)
        .toList(growable: false);
    return IdiomRepository(list);
  }

  List<Idiom> get all => _idioms;

  List<Idiom> get sorted =>
      [..._idioms]
        ..sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));

  Idiom? byId(int id) => _byId[id];

  /// Laufende Tagesnummer (lokaler Kalendertag), unabhängig von Sommerzeit.
  static int dayNumber(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(2026, 1, 1)).inDays;

  /// Die Redewendung des Tages – für alle Nutzer am selben Tag gleich.
  Idiom forDay(DateTime date) => _idioms[_mod(dayNumber(date), _idioms.length)];

  /// Redewendung für eine zusätzliche Benachrichtigung am selben Tag.
  /// Slot 0 ist immer die Redewendung des Tages.
  Idiom forSlot(DateTime date, int slot) {
    if (slot == 0) return forDay(date);
    final n = _idioms.length;
    final day = _mod(dayNumber(date), n);
    // Großer Schritt, damit sich die zusätzlichen Redewendungen nicht mit den
    // Tages-Redewendungen der nächsten Tage überschneiden.
    var idx = _mod(day + slot * 37 + 11, n);
    if (idx == day) idx = _mod(idx + 1, n);
    return _idioms[idx];
  }

  /// Redewendungen der Tage vor [today], neueste zuerst – höchstens bis
  /// [since] (z. B. erster Start der App) und höchstens [maxDays] Tage.
  List<({DateTime day, Idiom idiom})> history(
    DateTime today, {
    required DateTime since,
    int maxDays = 30,
  }) {
    final start = DateTime(since.year, since.month, since.day);
    final result = <({DateTime day, Idiom idiom})>[];
    for (var d = 1; d <= maxDays; d++) {
      final day = DateTime(today.year, today.month, today.day - d);
      if (day.isBefore(start)) break;
      result.add((day: day, idiom: forDay(day)));
    }
    return result;
  }

  /// Suche in Redewendung und Bedeutung. Alle Wörter der Anfrage müssen
  /// vorkommen; Umlaute und ß dürfen umschrieben werden („ueber“, „uber“).
  /// Treffer in der Redewendung selbst stehen vorne.
  List<Idiom> search(String query) {
    final words = normalize(
      query,
    ).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return sorted;
    final inText = <Idiom>[];
    final inMeaning = <Idiom>[];
    for (final i in sorted) {
      final text = normalize(i.text);
      final all = '$text ${normalize(i.meaning)}';
      if (!words.every(all.contains)) continue;
      (words.every(text.contains) ? inText : inMeaning).add(i);
    }
    return [...inText, ...inMeaning];
  }

  /// Kleinbuchstaben, Umlaute vereinfacht, Satzzeichen entfernt.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[äa]e?'), 'a')
      .replaceAll(RegExp('[öo]e?'), 'o')
      .replaceAll(RegExp('[üu]e?'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(' +'), ' ')
      .trim();

  static int _mod(int a, int n) => ((a % n) + n) % n;
}
