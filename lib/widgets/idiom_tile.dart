import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/idiom.dart';

class IdiomTile extends StatelessWidget {
  const IdiomTile({super.key, required this.idiom, this.caption});

  final Idiom idiom;

  /// Optional vor der Bedeutung, z. B. das Datum im Verlauf.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final fav = scope.state.isFavorite(idiom.id);
    return ListTile(
      title: Text(idiom.text, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        caption == null ? idiom.meaning : '$caption · ${idiom.meaning}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: fav ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
        icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
            color: fav ? Theme.of(context).colorScheme.error : null),
        onPressed: () => scope.state.toggleFavorite(idiom.id),
      ),
      onTap: () => AppScope.openIdiom(context, idiom),
    );
  }
}
