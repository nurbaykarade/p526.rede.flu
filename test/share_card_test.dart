import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redewendix/models/idiom.dart';
import 'package:redewendix/screens/share_screen.dart';

void main() {
  final idioms =
      (jsonDecode(File('assets/idioms.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>()
          .map(Idiom.fromJson)
          .toList();

  testWidgets('Bild-Karte läuft bei keiner Redewendung über', (tester) async {
    for (final idiom in idioms) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: ShareCard(idiom: idiom)),
        ),
      );
      expect(tester.takeException(), isNull, reason: idiom.text);
    }
  });
}
