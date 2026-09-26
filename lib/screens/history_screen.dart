import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../util/german_date.dart';
import '../widgets/idiom_tile.dart';

/// Die Redewendungen der letzten Tage.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final now = DateTime.now();
    final items = scope.repo.history(now, since: scope.state.firstLaunch);

    return Scaffold(
      appBar: AppBar(title: const Text('Verlauf')),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Hier erscheinen die Redewendungen der letzten Tage.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => IdiomTile(
                idiom: items[i].idiom,
                caption: formatPastDay(items[i].day, now),
              ),
            ),
    );
  }
}
