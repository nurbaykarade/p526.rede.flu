import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Zentrale App-Einstellungen (Favoriten, Benachrichtigungen).
class AppState extends ChangeNotifier {
  AppState._(this._prefs) {
    _multiPerDay = _prefs.getBool(_kMultiPerDay) ?? false;
    _favorites = (_prefs.getStringList(_kFavorites) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    _notificationsEnabled = _prefs.getBool(_kNotifEnabled) ?? true;
    _permissionAsked = _prefs.getBool(_kPermissionAsked) ?? false;
    _dailyHour = _prefs.getInt(_kDailyHour) ?? 8;
    _dailyMinute = _prefs.getInt(_kDailyMinute) ?? 0;
    _proStartHour = _prefs.getInt(_kProStart) ?? 8;
    _proEndHour = _prefs.getInt(_kProEnd) ?? 20;
    _proIntervalHours = _prefs.getInt(_kProInterval) ?? 1;
    _themeMode = ThemeMode.values[
        (_prefs.getInt(_kThemeMode) ?? 0).clamp(0, ThemeMode.values.length - 1)];
    _textScale = _prefs.getDouble(_kTextScale) ?? 1.0;
  }

  static Future<AppState> load() async =>
      AppState._(await SharedPreferences.getInstance());

  static const _kMultiPerDay = 'multiPerDay';
  static const _kFavorites = 'favorites';
  static const _kNotifEnabled = 'notificationsEnabled';
  static const _kPermissionAsked = 'permissionAsked';
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
  late Set<int> _favorites;
  late bool _notificationsEnabled;
  late bool _permissionAsked;
  late int _dailyHour;
  late int _dailyMinute;
  late int _proStartHour;
  late int _proEndHour;
  late int _proIntervalHours;
  late ThemeMode _themeMode;
  late double _textScale;

  /// true = mehrmals täglich im Zeitfenster, false = einmal täglich.
  bool get multiPerDay => _multiPerDay;
  Set<int> get favorites => Set.unmodifiable(_favorites);
  bool get notificationsEnabled => _notificationsEnabled;
  bool get permissionAsked => _permissionAsked;
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
        _kFavorites, _favorites.map((e) => e.toString()).toList());
  }

  Future<void> setMultiPerDay(bool value) async {
    if (_multiPerDay == value) return;
    _multiPerDay = value;
    notifyListeners();
    await _prefs.setBool(_kMultiPerDay, value);
    onScheduleChanged?.call();
  }

  Future<void> setPermissionAsked() async {
    _permissionAsked = true;
    notifyListeners();
    await _prefs.setBool(_kPermissionAsked, true);
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

  Future<void> setProWindow({int? startHour, int? endHour, int? interval}) async {
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
