import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/quiz.dart';
import 'pro_screen.dart';
import 'quiz_screen.dart';

/// Tab „Lernen“: Quiz und Lernstatistik (Pro).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final theme = Theme.of(context);
    final now = DateTime.now();

    if (!state.isPro) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Icon(Icons.quiz_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Quiz und Lernstatistik',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Teste dich mit Fragen zu den Redewendungen, markiere, was du '
            'schon kanntest, und sieh deinen Fortschritt.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Mit Pro freischalten'),
            onPressed: () => ProScreen.open(context),
          ),
        ],
      );
    }

    // Gesehen: Verlauf, heute und Favoriten.
    final seen = {
      scope.repo.forDay(now).id,
      for (final h in scope.repo.history(
        now,
        since: state.firstLaunch,
        maxDays: 365,
      ))
        h.idiom.id,
      ...state.favorites,
    };
    final pool = scope.repo.all.where((i) => seen.contains(i.id)).toList();
    final rate = state.quizAnswered == 0
        ? '–'
        : '${(100 * state.quizCorrect / state.quizAnswered).round()} %';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  pool.length >= 10
                      ? '10 Fragen zu Redewendungen, die du schon gesehen hast.'
                      : '10 Fragen zu allen Redewendungen.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Quiz starten'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuizScreen(
                        questions: buildQuiz(all: scope.repo.all, pool: pool),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Dein Fortschritt', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in <Widget>[
                  _Stat(
                    Icons.local_fire_department_outlined,
                    '${state.streak(now)}',
                    'Tage in Folge',
                  ),
                  _Stat(Icons.visibility_outlined, '${pool.length}', 'gesehen'),
                  _Stat(
                    Icons.check_circle_outline,
                    '${state.knownIds.length}',
                    'kannte ich schon',
                  ),
                  _Stat(
                    Icons.favorite_border,
                    '${state.favorites.length}',
                    'Favoriten',
                  ),
                  _Stat(
                    Icons.quiz_outlined,
                    '${state.quizRounds}',
                    'Quiz-Runden',
                  ),
                  _Stat(Icons.percent, rate, 'richtig beantwortet'),
                ])
                  SizedBox(width: w, child: stat),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
