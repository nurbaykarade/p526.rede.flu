import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:redewendix/config.dart';
import 'package:redewendix/services/app_state.dart';
import 'package:redewendix/services/pro_service.dart';

import 'test_helpers.dart';

class FakeStore implements InAppPurchase {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  int buys = 0;
  int restores = 0;
  final completed = <PurchaseDetails>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          ProductDetails(
            id: kProProductId,
            title: 'Redewendix Pro',
            description: '',
            price: '2,99 €',
            rawPrice: 2.99,
            currencyCode: 'EUR',
          ),
        ],
        notFoundIDs: const [],
      );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buys++;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails purchase(PurchaseStatus status, {String id = kProProductId}) =>
    PurchaseDetails(
      purchaseID: '1',
      productID: id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = true;

void main() {
  group('ProService', () {
    late FakeStore store;
    late AppState state;
    late ProService pro;

    setUp(() async {
      store = FakeStore();
      state = await testState();
      pro = ProService(store: store);
      await pro.init(state);
    });

    test('lädt den Preis aus dem Store', () {
      expect(pro.available, isTrue);
      expect(pro.price, '2,99 €');
    });

    test('Kauf schaltet Pro frei und schließt die Transaktion ab', () async {
      await pro.buy();
      expect(store.buys, 1);
      expect(pro.busy, isTrue);

      store.purchases.add([purchase(PurchaseStatus.purchased)]);
      await pumpEventQueue();

      expect(state.isPro, isTrue);
      expect(pro.busy, isFalse);
      expect(store.completed, hasLength(1));
      expect((await AppState.load()).isPro, isTrue);
    });

    test('Wiederherstellen schaltet Pro frei', () async {
      await pro.restore();
      expect(store.restores, 1);
      store.purchases.add([purchase(PurchaseStatus.restored)]);
      await pumpEventQueue();
      expect(state.isPro, isTrue);
    });

    test('Fehler und Abbruch schalten nichts frei', () async {
      store.purchases.add([purchase(PurchaseStatus.error)]);
      await pumpEventQueue();
      expect(state.isPro, isFalse);
      expect(pro.error, isNotNull);

      store.purchases.add([purchase(PurchaseStatus.canceled)]);
      await pumpEventQueue();
      expect(state.isPro, isFalse);
      expect(pro.busy, isFalse);
    });

    test('fremde Produkte werden ignoriert', () async {
      store.purchases.add([purchase(PurchaseStatus.purchased, id: 'x')]);
      await pumpEventQueue();
      expect(state.isPro, isFalse);
    });
  });

  group('Mehrmals täglich ist Pro', () {
    test('neue Nutzer brauchen Pro', () async {
      final s = await testState();
      await s.setMultiPerDay(true);
      expect(s.canUseMultiPerDay, isFalse);
      expect(s.multiPerDayActive, isFalse);
      await s.setPro(true);
      expect(s.multiPerDayActive, isTrue);
    });

    test('wer es vor 1.1 genutzt hat, behält es', () async {
      final s = await testState({'multiPerDay': true});
      expect(s.canUseMultiPerDay, isTrue);
      expect(s.multiPerDayActive, isTrue);
      expect((await AppState.load()).canUseMultiPerDay, isTrue);
    });

    test('später eingeschaltet zählt nicht als Altbestand', () async {
      final s = await testState();
      await s.setMultiPerDay(true);
      expect((await AppState.load()).canUseMultiPerDay, isFalse);
    });

    testWidgets('Schalter ohne Pro öffnet die Pro-Seite', (tester) async {
      final state = await testState({'permissionAsked': true});
      await tester.pumpWidget(testApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Einstellungen').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mehrmals täglich'));
      await tester.pumpAndSettle();

      expect(find.text('Einmal kaufen, für immer nutzen'), findsOneWidget);
      expect(state.multiPerDay, isFalse);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
