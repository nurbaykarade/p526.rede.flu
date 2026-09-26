import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Zentrale App-Einstellungen (Favoriten, Benachrichtigungen).
class AppState extends ChangeNotifier {
  AppState._(this._prefs) {
    _multiPerDay = _prefs.getBool(_kMultiPerDay) ?? false;
    _isPro = _prefs.getBool(_kIsPro) ?? false;
    // Wer „Mehrmals täglich“ schon vor 1.1 (damals kostenlos) genutzt hat,
    // behält es auch ohne Pro.
    if (!(_prefs.getBool(_kProGateSeen) ?? false)) {
      if (_multiPerDay) _prefs.setBool(_kMultiGrandfathered, true);
      _prefs.setBool(_kProGateSeen, true);
    }
    _multiGrandfathered = _prefs.getBool(_kMultiGrandfathered) ?? false;
    _favorites = (_prefs.getStringList(_kFavorites) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    _notificationsEnabled = _prefs.getBool(_kNotifEnabled) ?? true;
    _permissionAsked = _prefs.getBool(_kPermissionAsked) ?? false;
    // Wer schon nach Mitteilungen gefragt wurde, kennt die App bereits.
    _onboardingDone = _prefs.getBool(_kOnboardingDone) ?? _permissionAsked;
    final first = DateTime.tryParse(_prefs.getString(_kFirstLaunch) ?? '');
    _firstLaunch = first ?? DateTime.now();
    if (first == null) {
      _prefs.setString(_kFirstLaunch, _firstLaunch.toIso8601String());
    }
    _dailyHour = _prefs.getInt(_kDailyHour) ?? 8;
    _dailyMinute = _prefs.getInt(_kDailyMinute) ?? 0;
    _proStartHour = _prefs.getInt(_kProStart) ?? 8;
    _proEndHour = _prefs.getInt(_kProEnd) ?? 20;
    _proIntervalHours = _prefs.getInt(_kProInterval) ?? 1;
    _themeMode =
        ThemeMode.values[(_prefs.getInt(_kThemeMode) ?? 0).clamp(
          0,
          ThemeMode.values.length - 1,
        )];
    _textScale = _prefs.getDouble(_kTextScale) ?? 1.0;
  }

  static Future<AppState> load() async =>
      AppState._(await SharedPreferences.getInstance());

  static const _kMultiPerDay = 'multiPerDay';
  static const _kIsPro = 'isPro';
  static const _kAdDay = 'adDay';
  static const _kAdOpens = 'adDetailOpens';
  static const _kAdShown = 'adInterstitialShown';
  static const _kProGateSeen = 'proGateSeen';
  static const _kMultiGrandfathered = 'multiGrandfathered';
  static const _kFavorites = 'favorites';
  static const _kNotifEnabled = 'notificationsEnabled';
  static const _kPermissionAsked = 'permissionAsked';
  static const _kOnboardingDone = 'onboardingDone';
  static const _kFirstLaunch = 'firstLaunch';
  static const _kDailyHour = 'dailyHour';
  static const _kDailyMinute = 'dailyMinute';
  static const _kProStart = 'proStartHour';
  static const _kProEnd = 'proEndHour';
  static const _kProInterval = 'proIntervalHours';
  static const _kThemeMode = 'themeMode';
  static const _kTextScale = 'textScale';

  /// Wählbare Schriftgrößen (Faktor zusätzlich zur System-Einstellung).
  static const textScales = [1.0, 1.15, 1.3];

  final SharedPreferences _prefs;

  /// Wird aufgerufen, wenn sich etwas ändert, das die geplanten
  /// Benachrichtigungen betrifft.
  VoidCallback? onScheduleChanged;

  late bool _multiPerDay;
  late bool _isPro;
  late bool _multiGrandfathered;
  late Set<int> _favorites;
  late bool _notificationsEnabled;
  late bool _permissionAsked;
  late bool _onboardingDone;
  late DateTime _firstLaunch;
  late int _dailyHour;
  late int _dailyMinute;
  late int _proStartHour;
  late int _proEndHour;
  late int _proIntervalHours;
  late ThemeMode _themeMode;
  late double _textScale;

  /// Gewählt: mehrmals täglich im Zeitfenster (true) oder einmal täglich.
  bool get multiPerDay => _multiPerDay;

  /// Redewendix Pro gekauft.
  bool get isPro => _isPro;

  /// „Mehrmals täglich“ ist Pro – außer für Nutzer, die es schon vor 1.1
  /// eingeschaltet hatten.
  bool get canUseMultiPerDay => _isPro || _multiGrandfathered;

  /// Tatsächlich wirksam: gewählt und freigeschaltet.
  bool get multiPerDayActive => _multiPerDay && canUseMultiPerDay;
  Set<int> get favorites => Set.unmodifiable(_favorites);
  bool get notificationsEnabled => _notificationsEnabled;
  bool get permissionAsked => _permissionAsked;
  bool get onboardingDone => _onboardingDone;

  /// Erster Start der App – ab hier gibt es einen Verlauf.
  DateTime get firstLaunch => _firstLaunch;
  int get dailyHour => _dailyHour;
  int get dailyMinute => _dailyMinute;
  int get proStartHour => _proStartHour;
  int get proEndHour => _proEndHour;
  int get proIntervalHours => _proIntervalHours;
  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;

  bool isFavorite(int id) => _favorites.contains(id);

  Future<void> toggleFavorite(int id) async {
    if (!_favorites.remove(id)) _favorites.add(id);
    notifyListeners();
    await _prefs.setStringList(
      _kFavorites,
      _favorites.map((e) => e.toString()).toList(),
    );
  }

  Future<void> setMultiPerDay(bool value) async {
    if (_multiPerDay == value) return;
    _multiPerDay = value;
    notifyListeners();
    await _prefs.setBool(_kMultiPerDay, value);
    onScheduleChanged?.call();
  }

  // --- Werbung: höchstens ein Vollbild-Anzeige pro Tag ----------------------

  /// Wie oft heute eine Detailseite in der App geöffnet wurde.
  int detailOpensToday(DateTime now) =>
      _prefs.getString(_kAdDay) == _day(now) ? (_prefs.getInt(_kAdOpens) ?? 0) : 0;

  /// Ob heute schon eine Vollbild-Anzeige kam.
  bool interstitialShownToday(DateTime now) =>
      _prefs.getString(_kAdDay) == _day(now) && (_prefs.getBool(_kAdShown) ?? false);

  Future<void> countDetailOpen(DateTime now) async {
    await _rollAdDay(now);
    await _prefs.setInt(_kAdOpens, detailOpensToday(now) + 1);
  }

  Future<void> markInterstitialShown(DateTime now) async {
    await _rollAdDay(now);
    await _prefs.setBool(_kAdShown, true);
  }

  Future<void> _rollAdDay(DateTime now) async {
    if (_prefs.getString(_kAdDay) == _day(now)) return;
    await _prefs.setString(_kAdDay, _day(now));
    await _prefs.setInt(_kAdOpens, 0);
    await _prefs.setBool(_kAdShown, false);
  }

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> setPro(bool value) async {
    if (_isPro == value) return;
    _isPro = value;
    notifyListeners();
    await _prefs.setBool(_kIsPro, value);
    onScheduleChanged?.call();
  }

  Future<void> setPermissionAsked() async {
    _permissionAsked = true;
    notifyListeners();
    await _prefs.setBool(_kPermissionAsked, true);
  }

  Future<void> setOnboardingDone() async {
    _onboardingDone = true;
    notifyListeners();
    await _prefs.setBool(_kOnboardingDone, true);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kNotifEnabled, value);
    onScheduleChanged?.call();
  }

  Future<void> setDailyTime(int hour, int minute) async {
    _dailyHour = hour;
    _dailyMinute = minute;
    notifyListeners();
    await _prefs.setInt(_kDailyHour, hour);
    await _prefs.setInt(_kDailyMinute, minute);
    onScheduleChanged?.call();
  }

  Future<void> setProWindow({
    int? startHour,
    int? endHour,
    int? interval,
  }) async {
    _proStartHour = startHour ?? _proStartHour;
    _proEndHour = endHour ?? _proEndHour;
    _proIntervalHours = interval ?? _proIntervalHours;
    if (_proEndHour < _proStartHour) _proEndHour = _proStartHour;
    notifyListeners();
    await _prefs.setInt(_kProStart, _proStartHour);
    await _prefs.setInt(_kProEnd, _proEndHour);
    await _prefs.setInt(_kProInterval, _proIntervalHours);
    onScheduleChanged?.call();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    await _prefs.setDouble(_kTextScale, scale);
  }
}
