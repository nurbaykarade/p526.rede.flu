import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_state.dart';
import 'idiom_repository.dart';
import 'schedule.dart';

/// Zeigt die Redewendungen als Benachrichtigung – dadurch erscheinen sie
/// auf dem Sperrbildschirm (Android und iOS).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<int> _taps = StreamController<int>.broadcast();

  /// Idiom-IDs aus angetippten Benachrichtigungen (App läuft bereits).
  Stream<int> get taps => _taps.stream;

  /// Idiom-ID, falls die App durch Antippen einer Benachrichtigung
  /// gestartet wurde.
  int? launchIdiomId;

  static const _reminderId = 999;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_idiom',
      'Redewendung des Tages',
      channelDescription: 'Zeigt Redewendungen auf dem Sperrbildschirm an.',
      icon: 'ic_stat_redewendix',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: false,
    ),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_redewendix'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null) _taps.add(id);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchIdiomId = int.tryParse(launch!.notificationResponse?.payload ?? '');
    }
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: false, sound: true) ??
          false;
    }
    return false;
  }

  /// Plant alle Benachrichtigungen neu. Wird beim Start, beim Zurückkehren
  /// in die App und bei jeder Einstellungsänderung aufgerufen.
  Future<void> reschedule(AppState state, IdiomRepository repo) async {
    await _plugin.cancelAll();
    if (!state.notificationsEnabled || !state.permissionAsked) return;

    final now = DateTime.now();
    final slots = computeSchedule(
      now: now,
      multiPerDay: state.multiPerDay,
      dailyHour: state.dailyHour,
      dailyMinute: state.dailyMinute,
      proStartHour: state.proStartHour,
      proEndHour: state.proEndHour,
      proIntervalHours: state.proIntervalHours,
    );

    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      final idiom = repo.forSlot(s.time, s.slot);
      await _plugin.zonedSchedule(
        id: i,
        // Absoluter Zeitpunkt; die lokale Zeitzone steckt bereits in s.time.
        scheduledDate: tz.TZDateTime.from(s.time, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: s.slot == 0 ? 'Redewendung des Tages' : 'Redewendix',
        body: '„${idiom.text}“ – ${idiom.meaning}',
        payload: '${idiom.id}',
      );
    }

    // Wenn der Vorrat ausläuft (mehrmals täglich, App lange nicht geöffnet),
    // erinnert eine letzte Benachrichtigung daran, die App zu öffnen.
    if (state.multiPerDay && slots.length >= kMaxScheduled) {
      final last = slots.last.time;
      await _plugin.zonedSchedule(
        id: _reminderId,
        scheduledDate:
            tz.TZDateTime.from(last.add(const Duration(hours: 1)), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Redewendix',
        body: 'Öffne die App, um neue Redewendungen zu laden.',
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // --- Diagnose ---------------------------------------------------------

  /// Ob das System Mitteilungen für die App erlaubt.
  Future<bool> isPermitted() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (Platform.isIOS) {
      final o = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return o?.isEnabled ?? false;
    }
    return false;
  }

  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;

  /// Zeigt sofort eine Mitteilung mit der Redewendung des Tages.
  Future<void> showTestNow(IdiomRepository repo) async {
    final idiom = repo.forDay(DateTime.now());
    await _plugin.show(
      id: 900,
      title: 'Redewendung des Tages',
      body: '„${idiom.text}“ – ${idiom.meaning}',
      notificationDetails: _details,
      payload: '${idiom.id}',
    );
  }

  /// Plant eine Test-Mitteilung in einer Minute (App schließen, Handy sperren).
  Future<void> scheduleTestInOneMinute(IdiomRepository repo) async {
    final idiom = repo.forSlot(DateTime.now(), 1);
    await _plugin.zonedSchedule(
      id: 901,
      scheduledDate: tz.TZDateTime.from(
          DateTime.now().add(const Duration(minutes: 1)), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Redewendix (Test)',
      body: '„${idiom.text}“ – ${idiom.meaning}',
      payload: '${idiom.id}',
    );
  }

  Future<void> openSystemSettings() async {
    await _plugin.openAppNotificationSettings();
  }
}
