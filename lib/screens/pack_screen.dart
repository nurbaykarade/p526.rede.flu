import 'package:flutter/material.dart';

import '../services/idiom_repository.dart';
import '../widgets/idiom_tile.dart';

/// Alle Redewendungen eines Zusatz-Pakets.
class PackScreen extends StatelessWidget {
  const PackScreen({super.key, required this.pack});

  final IdiomPack pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [...pack.idioms]
      ..sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    return Scaffold(
      appBar: AppBar(title: Text(pack.title)),
      body: ListView.separated(
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => i == 0
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  pack.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : IdiomTile(idiom: items[i - 1]),
      ),
    );
  }
}
