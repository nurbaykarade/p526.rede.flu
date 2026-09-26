import 'package:flutter/material.dart';
import 'package:redewendix/main.dart';
import 'package:redewendix/models/idiom.dart';
import 'package:redewendix/services/app_state.dart';
import 'package:redewendix/services/idiom_repository.dart';
import 'package:redewendix/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ersetzt das Plugin in Widget-Tests (dort gibt es keine Plattform).
class FakeNotificationService extends NotificationService {
  int permissionRequests = 0;
  int reschedules = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> reschedule(AppState state, IdiomRepository repo) async {
    reschedules++;
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> isPermitted() async => true;

  @override
  Future<int> pendingCount() async => 0;
}

IdiomRepository testRepo([int count = 10]) => IdiomRepository([
  for (var i = 1; i <= count; i++)
    Idiom(
      id: i,
      text: 'Redewendung Nummer $i',
      meaning: 'Bedeutung $i',
      origin: 'Herkunft $i',
      example: 'Beispiel $i',
    ),
]);

Future<AppState> testState([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return AppState.load();
}

Widget testApp({
  required AppState state,
  IdiomRepository? repo,
  NotificationService? notifications,
}) => RedewendixApp(
  state: state,
  repo: repo ?? testRepo(),
  notifications: notifications ?? FakeNotificationService(),
);
