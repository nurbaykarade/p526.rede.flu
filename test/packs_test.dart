import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:redewendix/models/idiom.dart';
import 'package:redewendix/screens/learn_screen.dart';
import 'package:redewendix/services/idiom_repository.dart';

import 'test_helpers.dart';

IdiomRepository repoWithPack() => IdiomRepository(
  testRepo().all,
  packs: const [
    IdiomPack(
      id: 'test',
      title: 'Testpaket',
      description: 'Ein Paket für Tests.',
      idioms: [
        Idiom(
          id: 1001,
          text: 'Paket-Redewendung',
          meaning: 'Paket-Bedeutung',
          origin: 'o',
          example: 'e',
        ),
      ],
    ),
  ],
);

void main() {
  test('Paket-Redewendungen sind nicht in der täglichen Auswahl', () {
    final repo = repoWithPack();
    expect(repo.byId(1001)?.text, 'Paket-Redewendung');
    expect(repo.all.any((i) => i.id == 1001), isFalse);
    for (var d = 0; d < 30; d++) {
      expect(repo.forDay(DateTime(2026, 10, 1 + d)).id, isNot(1001));
    }
    expect(repo.sortedWithPacks.any((i) => i.id == 1001), isTrue);
  });

  testWidgets('Ohne Pro: Paket gesperrt', (tester) async {
    final state = await testState({'permissionAsked': true});
    await tester.pumpWidget(testApp(state: state, repo: repoWithPack()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lernen').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Testpaket'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(LearnScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Testpaket'));
    await tester.pumpAndSettle();
    expect(find.text('Einmal kaufen, für immer nutzen'), findsOneWidget);
  });

  testWidgets('Mit Pro: Paket öffnen, Favorit merken', (tester) async {
    final state = await testState({'permissionAsked': true, 'isPro': true});
    await tester.pumpWidget(testApp(state: state, repo: repoWithPack()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lernen').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Testpaket'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(LearnScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Testpaket'));
    await tester.pumpAndSettle();

    expect(find.text('Paket-Redewendung'), findsOneWidget);
    await tester.tap(find.byTooltip('Zu Favoriten'));
    await tester.pumpAndSettle();
    expect(state.isFavorite(1001), isTrue);
  });
}
