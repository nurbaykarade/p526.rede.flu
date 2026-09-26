import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/app_state.dart';
import '../util/german_date.dart';
import 'pro_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _intervals = [1, 2, 3, 4, 6];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final state = scope.state;
    final theme = Theme.of(context);

    return ListView(
      children: [
        ListTile(
          leading: Icon(
            state.isPro ? Icons.verified : Icons.workspace_premium_outlined,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Redewendix Pro'),
          subtitle: Text(
            state.isPro
                ? 'Aktiv – danke!'
                : 'Keine Werbung, mehrmals täglich, Quiz und mehr',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ProScreen.open(context),
        ),
        const Divider(),
        const _Header('Sperrbildschirm'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Redewendungen anzeigen'),
          subtitle: const Text('Als Mitteilung auf dem Sperrbildschirm'),
          value: state.notificationsEnabled && state.permissionAsked,
          onChanged: (v) async {
            if (v && !state.permissionAsked) {
              await scope.notifications.requestPermission();
              await state.setPermissionAsked();
            }
            await state.setNotificationsEnabled(v);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.repeat),
          title: const Text('Mehrmals täglich'),
          subtitle: Text(
            state.canUseMultiPerDay
                ? 'Neue Redewendungen in einem Zeitfenster'
                : 'Mit Pro: neue Redewendungen in einem Zeitfenster',
          ),
          value: state.multiPerDayActive,
          onChanged: !state.notificationsEnabled
              ? null
              : state.canUseMultiPerDay
                  ? state.setMultiPerDay
                  : (_) => ProScreen.open(context),
        ),
        if (!state.multiPerDayActive)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Uhrzeit'),
            subtitle: const Text('Einmal täglich'),
            trailing: Text(
              formatTime(state.dailyHour, state.dailyMinute),
              style: theme.textTheme.titleMedium,
            ),
            enabled: state.notificationsEnabled,
            onTap: () async {
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
        if (state.multiPerDayActive) ...[
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('Häufigkeit'),
            trailing: DropdownButton<int>(
              value: _intervals.contains(state.proIntervalHours)
                  ? state.proIntervalHours
                  : 1,
              underline: const SizedBox.shrink(),
              items: [
                for (final h in _intervals)
                  DropdownMenuItem(
                    value: h,
                    child: Text(h == 1 ? 'stündlich' : 'alle $h Stunden'),
                  ),
              ],
              onChanged: (v) => state.setProWindow(interval: v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Von'),
            trailing: _HourDropdown(
              value: state.proStartHour,
              onChanged: (v) => state.setProWindow(startHour: v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_outlined),
            title: const Text('Bis'),
            trailing: _HourDropdown(
              value: state.proEndHour,
              min: state.proStartHour,
              onChanged: (v) => state.setProWindow(endHour: v),
            ),
          ),
        ],
        const Divider(),
        const _Header('Mitteilungen'),
        const _NotificationStatus(),
        ListTile(
          leading: const Icon(Icons.settings_applications_outlined),
          title: const Text('Mitteilungs-Einstellungen des Systems'),
          onTap: scope.notifications.openSystemSettings,
        ),
        // Test-Mitteilungen nur in Debug-Builds.
        if (kDebugMode) ...[
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Test-Mitteilung jetzt'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await scope.notifications.showTestNow(scope.repo);
              messenger.showSnackBar(
                const SnackBar(content: Text('Test-Mitteilung gesendet')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_clock_outlined),
            title: const Text('Test in 1 Minute'),
            subtitle: const Text('Danach App schließen und Handy sperren'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await scope.notifications.scheduleTestInOneMinute(scope.repo);
              messenger.showSnackBar(
                const SnackBar(content: Text('Test in 1 Minute geplant')),
              );
            },
          ),
        ],
        const Divider(),
        const _Header('Darstellung'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Hell'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dunkel'),
              ),
            ],
            selected: {state.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => state.setThemeMode(s.first),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.format_size),
          title: Text('Schriftgröße'),
          subtitle: Text('Zusätzlich zur Einstellung des Handys'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 1.0, label: Text('Normal')),
              ButtonSegment(value: 1.15, label: Text('Groß')),
              ButtonSegment(value: 1.3, label: Text('Sehr groß')),
            ],
            selected: {
              AppState.textScales.contains(state.textScale)
                  ? state.textScale
                  : 1.0,
            },
            showSelectedIcon: false,
            onSelectionChanged: (s) => state.setTextScale(s.first),
          ),
        ),
        const Divider(),
        ListenableBuilder(
          listenable: scope.ads,
          builder: (context, _) => scope.ads.privacyOptionsRequired
              ? ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Datenschutz-Einstellungen'),
                  subtitle: const Text('Einwilligung für Werbung ändern'),
                  onTap: scope.ads.showPrivacyOptions,
                )
              : const SizedBox.shrink(),
        ),
        const AboutListTile(
          icon: Icon(Icons.info_outline),
          applicationName: 'Redewendix',
          applicationVersion: '1.0.0',
          applicationLegalese: 'Jeden Tag eine deutsche Redewendung.',
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value < min ? min : value;
    return DropdownButton<int>(
      value: v,
      underline: const SizedBox.shrink(),
      items: [
        for (var h = min; h <= 23; h++)
          DropdownMenuItem(value: h, child: Text(formatTime(h, 0))),
      ],
      onChanged: (h) {
        if (h != null) onChanged(h);
      },
    );
  }
}

class _NotificationStatus extends StatefulWidget {
  const _NotificationStatus();

  @override
  State<_NotificationStatus> createState() => _NotificationStatusState();
}

class _NotificationStatusState extends State<_NotificationStatus> {
  bool? _permitted;
  int? _pending;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final n = AppScope.read(context).notifications;
    final permitted = await n.isPermitted();
    final pending = await n.pendingCount();
    if (mounted) {
      setState(() {
        _permitted = permitted;
        _pending = pending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // bei Einstellungsänderungen neu laden
    final ok = _permitted == true;
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        color: ok ? Colors.green : Theme.of(context).colorScheme.error,
      ),
      title: Text(
        _permitted == null
            ? 'Status wird geprüft …'
            : ok
            ? 'Mitteilungen erlaubt'
            : 'Mitteilungen im System blockiert',
      ),
      subtitle: Text('Geplant: ${_pending ?? '–'} Mitteilungen'),
      trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
    );
  }
}
