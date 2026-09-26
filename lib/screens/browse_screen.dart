import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/ad_banner.dart';
import '../widgets/idiom_tile.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final items = scope.repo.search(_query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            hintText: 'Redewendung oder Bedeutung …',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Keine Treffer'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => IdiomTile(idiom: items[i]),
                ),
        ),
        const AdBanner(),
      ],
    );
  }
}
