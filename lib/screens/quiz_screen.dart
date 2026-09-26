import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/quiz.dart';

/// Eine Quiz-Runde: Redewendung → richtige Bedeutung wählen.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.questions});

  final List<QuizQuestion> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _correct = 0;
  String? _chosen;
  bool _done = false;

  QuizQuestion get _q => widget.questions[_index];

  void _choose(String option) {
    if (_chosen != null) return;
    setState(() {
      _chosen = option;
      if (_q.isCorrect(option)) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _chosen = null;
      });
      return;
    }
    await AppScope.read(
      context,
    ).state.recordQuiz(correct: _correct, total: widget.questions.length);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_done ? 'Ergebnis' : 'Frage ${_index + 1} von $total'),
        bottom: _done
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: (_index + 1) / total),
              ),
      ),
      body: _done ? _result(theme, total) : _question(theme),
    );
  }

  Widget _question(ThemeData theme) {
    final q = _q;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Was bedeutet …', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '„${q.idiom.text}“',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        for (final option in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              text: option,
              state: _chosen == null
                  ? _OptionState.open
                  : q.isCorrect(option)
                  ? _OptionState.correct
                  : option == _chosen
                  ? _OptionState.wrong
                  : _OptionState.dimmed,
              onTap: () => _choose(option),
            ),
          ),
        if (_chosen != null) ...[
          const SizedBox(height: 8),
          Text(
            q.idiom.example,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _next,
            child: Text(
              _index + 1 < widget.questions.length ? 'Weiter' : 'Ergebnis',
            ),
          ),
        ],
      ],
    );
  }

  Widget _result(ThemeData theme, int total) {
    final ratio = _correct / total;
    final (icon, text) = ratio >= 0.9
        ? (Icons.emoji_events_outlined, 'Hervorragend!')
        : ratio >= 0.6
        ? (Icons.thumb_up_outlined, 'Gut gemacht!')
        : (Icons.school_outlined, 'Übung macht den Meister.');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(icon, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          '$_correct von $total richtig',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig'),
        ),
      ],
    );
  }
}

enum _OptionState { open, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (state) {
      _OptionState.open => (c.surfaceContainerHighest, c.onSurface, null),
      _OptionState.correct => (
        c.primaryContainer,
        c.onPrimaryContainer,
        Icons.check_circle,
      ),
      _OptionState.wrong => (
        c.errorContainer,
        c.onErrorContainer,
        Icons.cancel,
      ),
      _OptionState.dimmed => (c.surfaceContainer, c.onSurfaceVariant, null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: state == _OptionState.open ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: TextStyle(color: fg, fontSize: 16)),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
