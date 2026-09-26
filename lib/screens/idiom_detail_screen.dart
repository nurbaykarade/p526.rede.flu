import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/idiom.dart';

class IdiomDetailScreen extends StatelessWidget {
  const IdiomDetailScreen({super.key, required this.idiom});

  final Idiom idiom;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final fav = scope.state.isFavorite(idiom.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redewendung'),
        actions: [
          IconButton(
            tooltip: fav ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? theme.colorScheme.error : null),
            onPressed: () => scope.state.toggleFavorite(idiom.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '„${idiom.text}“',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          _Section(icon: Icons.lightbulb_outline, title: 'Bedeutung', text: idiom.meaning),
          _Section(icon: Icons.history_edu_outlined, title: 'Herkunft', text: idiom.origin),
          _Section(
            icon: Icons.format_quote,
            title: 'Beispiel',
            text: idiom.example,
            italic: true,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.text,
    this.italic = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: italic ? FontStyle.italic : null,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
