import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../util/german_date.dart';

/// Kurze Einführung beim ersten Start. Am Ende wird nach der
/// Mitteilungs-Erlaubnis gefragt.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _busy = false;

  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  Future<void> _finish({required bool allow}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final scope = AppScope.read(context);
    if (allow) {
      await scope.notifications.requestPermission();
      await scope.state.setPermissionAsked();
    }
    await scope.state.setOnboardingDone();
    await scope.notifications.reschedule(scope.state, scope.repo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _count - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: last ? null : () => _pages.jumpToPage(_count - 1),
                child: Text(last ? '' : 'Überspringen'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [_Welcome(), _LockScreen(), _Permission()],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: last
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: _busy ? null : () => _finish(allow: true),
                          child: const Text('Mitteilungen erlauben'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : () => _finish(allow: false),
                          child: const Text('Später'),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: const Text('Weiter'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.title,
    required this.text,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 44,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            size: 44,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (extra != null) ...[const SizedBox(height: 24), extra!],
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => const _Page(
    icon: Icons.format_quote,
    title: 'Willkommen bei Redewendix',
    text:
        'Jeden Tag eine deutsche Redewendung – mit Bedeutung, '
        'Herkunft und einem Beispielsatz.',
  );
}

class _LockScreen extends StatelessWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final idiom = scope.repo.forDay(DateTime.now());
    final theme = Theme.of(context);

    return _Page(
      icon: Icons.lock_clock_outlined,
      title: 'Direkt auf dem Sperrbildschirm',
      text:
          'Die Redewendung des Tages erscheint als Mitteilung – '
          'ohne dass du die App öffnen musst.',
      extra: Column(
        children: [
          // Vorschau einer Mitteilung.
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Redewendung des Tages'),
              subtitle: Text(
                '„${idiom.text}“ – ${idiom.meaning}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(
              'Täglich um ${formatTime(state.dailyHour, state.dailyMinute)} Uhr',
            ),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: state.dailyHour,
                  minute: state.dailyMinute,
                ),
              );
              if (picked != null) {
                await state.setDailyTime(picked.hour, picked.minute);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Permission extends StatelessWidget {
  const _Permission();

  @override
  Widget build(BuildContext context) => const _Page(
    icon: Icons.notifications_active_outlined,
    title: 'Mitteilungen erlauben',
    text:
        'Damit die Redewendung auf dem Sperrbildschirm erscheinen kann, '
        'braucht Redewendix deine Erlaubnis. Du kannst das jederzeit in '
        'den Einstellungen ändern.',
  );
}
