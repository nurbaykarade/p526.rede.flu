import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/services/quiz.dart';

import 'test_helpers.dart';

void main() {
  group('buildQuiz', () {
    final all = testRepo(40).all;

    test('10 Fragen mit je 4 verschiedenen Antworten, eine richtig', () {
      final quiz = buildQuiz(all: all, pool: all, random: Random(1));
      expect(quiz, hasLength(10));
      expect(quiz.map((q) => q.idiom.id).toSet(), hasLength(10));
      for (final q in quiz) {
        expect(q.options.toSet(), hasLength(4));
        expect(q.options.where(q.isCorrect), hasLength(1));
      }
    });

    test('bevorzugt gesehene Redewendungen', () {
      final pool = all.take(12).toList();
      final quiz = buildQuiz(all: all, pool: pool, random: Random(2));
      expect(quiz.every((q) => pool.contains(q.idiom)), isTrue);
    });

    test('zu wenig gesehen: alle Redewendungen', () {
      final quiz = buildQuiz(all: all, pool: all.take(3).toList());
      expect(quiz, hasLength(10));
    });
  });

  group('Lernstatistik', () {
    test('Tage in Folge', () async {
      final s = await testState();
      await s.recordOpen(DateTime(2026, 10, 1));
      await s.recordOpen(DateTime(2026, 10, 2));
      await s.recordOpen(DateTime(2026, 10, 3, 22));
      expect(s.streak(DateTime(2026, 10, 3, 23)), 3);
      // Heute noch nicht geöffnet: die Serie bis gestern zählt noch.
      expect(s.streak(DateTime(2026, 10, 4, 8)), 3);
      expect(s.streak(DateTime(2026, 10, 5, 8)), 0);
    });

    test('Quiz-Ergebnisse und „kannte ich schon“', () async {
      final s = await testState();
      await s.recordQuiz(correct: 7, total: 10);
      await s.recordQuiz(correct: 9, total: 10);
      await s.setKnown(4, true);
      await s.setKnown(5, true);
      await s.setKnown(4, false);
      expect(
        (s.quizRounds, s.quizAnswered, s.quizCorrect, s.quizBest),
        (2, 20, 16, 9),
      );
      expect(s.knownIds, {5});
    });
  });

  testWidgets('Ohne Pro: Hinweis statt Quiz', (tester) async {
    final state = await testState({'permissionAsked': true});
    await tester.pumpWidget(testApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lernen').last);
    await tester.pumpAndSettle();
    expect(find.text('Mit Pro freischalten'), findsOneWidget);
    expect(find.text('Quiz starten'), findsNothing);
  });

  testWidgets('Mit Pro: eine ganze Quiz-Runde', (tester) async {
    final state = await testState({'permissionAsked': true, 'isPro': true});
    await tester.pumpWidget(testApp(state: state, repo: testRepo(20)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lernen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz starten'));
    await tester.pumpAndSettle();

    for (var i = 1; i <= 10; i++) {
      expect(find.text('Frage $i von 10'), findsOneWidget);
      // Immer die erste Antwort wählen.
      await tester.tap(find.textContaining('Bedeutung').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('von 10 richtig'), findsOneWidget);
    expect(state.quizRounds, 1);
    expect(state.quizAnswered, 10);
  });
}
