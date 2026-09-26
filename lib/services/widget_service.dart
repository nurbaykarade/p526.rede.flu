import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'idiom_repository.dart';

/// Versorgt das Startbildschirm-Widget (Android und iOS) mit Daten.
///
/// Das Widget bekommt die Redewendungen der nächsten [kWidgetDays] Tage, damit
/// es nach Mitternacht auch ohne geöffnete App die neue Redewendung zeigt.
class WidgetService {
  static const appGroupId = 'group.bq.p526.rede';
  static const androidName = 'IdiomWidgetProvider';
  static const iOSName = 'RedewendixWidget';

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Idiom-IDs aus angetippten Widgets (App läuft bereits).
  Stream<int> get taps => _supported
      ? HomeWidget.widgetClicked
            .map(idiomIdFromUri)
            .where((id) => id != null)
            .cast<int>()
      : const Stream.empty();

  Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Idiom-ID, falls die App über das Widget gestartet wurde.
  Future<int?> launchIdiomId() async {
    if (!_supported) return null;
    try {
      return idiomIdFromUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } catch (e) {
      debugPrint('Widget-Start: $e');
      return null;
    }
  }

  Future<void> update(IdiomRepository repo) async {
    if (!_supported) return;
    final now = DateTime.now();
    try {
      await HomeWidget.saveWidgetData<String>(
        'days',
        jsonEncode(widgetDays(repo, now)),
      );
      await HomeWidget.updateWidget(androidName: androidName, iOSName: iOSName);
      if (Platform.isAndroid) {
        await HomeWidget.scheduleWidgetUpdates([
          for (var d = 1; d <= kWidgetDays; d++)
            DateTime(now.year, now.month, now.day + d, 0, 1),
        ], androidName: androidName);
      }
    } catch (e) {
      // Kein Widget auf dem Startbildschirm o. Ä. – kein Grund abzustürzen.
      debugPrint('Widget-Update: $e');
    }
  }
}

const int kWidgetDays = 30;

/// Redewendungen für heute und die nächsten Tage, nach Datum (yyyy-MM-dd).
Map<String, Map<String, Object>> widgetDays(
  IdiomRepository repo,
  DateTime now, {
  int days = kWidgetDays,
}) {
  final result = <String, Map<String, Object>>{};
  for (var d = 0; d <= days; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    final idiom = repo.forDay(day);
    result[dateKey(day)] = {
      'id': idiom.id,
      'text': idiom.text,
      'meaning': idiom.meaning,
    };
  }
  return result;
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// redewendix://idiom/42 → 42
int? idiomIdFromUri(Uri? uri) {
  if (uri == null || uri.host != 'idiom' || uri.pathSegments.isEmpty) {
    return null;
  }
  return int.tryParse(uri.pathSegments.first);
}
