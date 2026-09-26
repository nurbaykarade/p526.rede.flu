import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../util/german_date.dart';

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
          subtitle: const Text('Neue Redewendungen in einem Zeitfenster'),
          value: state.multiPerDay,
          onChanged: state.notificationsEnabled ? state.setMultiPerDay : null,
        ),
        if (!state.multiPerDay)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Uhrzeit'),
            subtitle: const Text('Einmal täglich'),
            trailing: Text(formatTime(state.dailyHour, state.dailyMinute),
                style: theme.textTheme.titleMedium),
            enabled: state.notificationsEnabled,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: state.dailyHour, minute: state.dailyMinute),
              );
              if (picked != null) {
                await state.setDailyTime(picked.hour, picked.minute);
              }
            },
          ),
        if (state.multiPerDay) ...[
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
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({required this.value, required this.onChanged, this.min = 0});

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
