import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../util/german_date.dart';
import '../widgets/idiom_tile.dart';
import 'history_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final now = DateTime.now();
    final idiom = scope.repo.forDay(now);
    final fav = state.isFavorite(idiom.id);
    final theme = Theme.of(context);
    final history = scope.repo.history(now, since: state.firstLaunch);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(formatGermanDate(now),
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Redewendung des Tages', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => AppScope.openIdiom(context, idiom),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '„${idiom.text}“',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    idiom.meaning,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FilledButton.tonalIcon(
                          onPressed: () => AppScope.openIdiom(context, idiom),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Mehr erfahren'),
                        ),
                      ),
                      IconButton(
                        tooltip: fav ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
                        icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                            color: fav ? theme.colorScheme.error : null),
                        onPressed: () => state.toggleFavorite(idiom.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!state.permissionAsked) const _EnableNotificationsCard(),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Die letzten Tage', style: theme.textTheme.titleMedium),
          for (final h in history.take(3))
            IdiomTile(idiom: h.idiom, caption: formatPastDay(h.day, now)),
          if (history.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Ganzer Verlauf'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EnableNotificationsCard extends StatelessWidget {
  const _EnableNotificationsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lock_clock_outlined),
              const SizedBox(width: 8),
              Text('Auf dem Sperrbildschirm', style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Erlaube Mitteilungen, damit die Redewendung des Tages '
              'automatisch auf deinem Sperrbildschirm erscheint.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final scope = AppScope.read(context);
                await scope.notifications.requestPermission();
                await scope.state.setPermissionAsked();
                await scope.notifications.reschedule(scope.state, scope.repo);
              },
              child: const Text('Mitteilungen erlauben'),
            ),
          ],
        ),
      ),
    );
  }
}
