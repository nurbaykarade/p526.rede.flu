import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/idiom_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final favs = scope.repo.sortedWithPacks
        .where((i) => scope.state.isFavorite(i.id))
        .toList();

    if (favs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 48),
              SizedBox(height: 12),
              Text(
                'Noch keine Favoriten.\nTippe auf das Herz, um eine Redewendung zu speichern.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: favs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => IdiomTile(idiom: favs[i]),
    );
  }
}
