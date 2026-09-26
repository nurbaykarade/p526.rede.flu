import 'dart:math';

import '../models/idiom.dart';

class QuizQuestion {
  const QuizQuestion(this.idiom, this.options);

  final Idiom idiom;

  /// Vier Bedeutungen, eine davon richtig (in zufälliger Reihenfolge).
  final List<String> options;

  bool isCorrect(String option) => option == idiom.meaning;
}

/// Stellt eine Quiz-Runde zusammen: [count] Redewendungen aus [pool]
/// (bevorzugt die schon gesehenen), falsche Antworten aus [all].
List<QuizQuestion> buildQuiz({
  required List<Idiom> all,
  required List<Idiom> pool,
  int count = 10,
  Random? random,
}) {
  final rng = random ?? Random();
  final source = pool.length >= count ? pool : all;
  final picked = ([...source]..shuffle(rng)).take(count).toList();
  return [
    for (final idiom in picked)
      QuizQuestion(
        idiom,
        [
          idiom.meaning,
          ...([...all]..shuffle(rng))
              .where((o) => o.id != idiom.id && o.meaning != idiom.meaning)
              .map((o) => o.meaning)
              .toSet()
              .take(3),
        ]..shuffle(rng),
      ),
  ];
}
