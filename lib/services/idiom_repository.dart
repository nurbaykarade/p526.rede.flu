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

  List<Idiom> get sorted => [..._idioms]
    ..sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));

  Idiom? byId(int id) => _byId[id];

  /// Laufende Tagesnummer (lokaler Kalendertag), unabhängig von Sommerzeit.
  static int dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(2026, 1, 1))
          .inDays;

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

  static int _mod(int a, int n) => ((a % n) + n) % n;
}
