import 'package:flutter/material.dart';

import 'models/idiom.dart';
import 'screens/idiom_detail_screen.dart';
import 'services/app_state.dart';
import 'services/idiom_repository.dart';
import 'services/notification_service.dart';

/// Stellt alle Dienste im Widget-Baum bereit. Widgets, die [AppScope.of]
/// aufrufen, werden bei Änderungen an [AppState] neu gebaut.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required this.repo,
    required this.notifications,
    required super.child,
  }) : super(notifier: state);

  final IdiomRepository repo;
  final NotificationService notifications;

  AppState get state => notifier!;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope nicht gefunden');
    return scope!;
  }

  /// Zugriff ohne Abhängigkeit – für Callbacks außerhalb von build().
  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;

  /// Öffnet die Detailseite.
  static Future<void> openIdiom(BuildContext context, Idiom idiom) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => IdiomDetailScreen(idiom: idiom),
    ));
  }
}
