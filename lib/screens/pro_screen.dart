import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Was Pro bietet, Kauf und Wiederherstellen.
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ProScreen()));

  static const benefits = [
    (Icons.block, 'Keine Werbung'),
    (Icons.repeat, 'Mehrmals täglich eine neue Redewendung'),
    (Icons.quiz_outlined, 'Quiz und Lernstatistik'),
    (Icons.library_books_outlined, 'Zusätzliche Redewendungs-Pakete'),
  ];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Redewendix Pro')),
      body: ListenableBuilder(
        listenable: scope.pro,
        builder: (context, _) {
          final pro = scope.pro;
          final isPro = scope.state.isPro;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  isPro ? Icons.verified : Icons.workspace_premium_outlined,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPro
                    ? 'Danke für deine Unterstützung!'
                    : 'Einmal kaufen, für immer nutzen',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                isPro
                    ? 'Pro ist auf diesem Gerät aktiv.'
                    : 'Kein Abo – ein einmaliger Kauf für alle deine Geräte '
                          'mit demselben Store-Konto.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              for (final (icon, text) in benefits)
                ListTile(
                  leading: Icon(icon, color: theme.colorScheme.primary),
                  title: Text(text),
                  trailing: isPro ? const Icon(Icons.check) : null,
                ),
              const SizedBox(height: 24),
              if (!isPro) ...[
                FilledButton(
                  onPressed: pro.available && !pro.busy ? pro.buy : null,
                  child: pro.busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          pro.price == null
                              ? 'Pro freischalten'
                              : 'Pro freischalten – ${pro.price}',
                        ),
                ),
                if (!pro.available && !pro.busy)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Der Store ist gerade nicht erreichbar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: pro.busy ? null : pro.restore,
                  child: const Text('Käufe wiederherstellen'),
                ),
              ],
              if (pro.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    pro.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
