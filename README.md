# Redewendix (p526)

Jeden Tag eine deutsche Redewendung auf dem Sperrbildschirm.

- **Version 1.0 ist komplett kostenlos, ohne Werbung.** Werbung und ein einmaliger Pro-Kauf kommen mit 1.1.
- Einmal täglich zu einer wählbaren Uhrzeit oder mehrmals täglich (bis stündlich) in einem eigenen Zeitfenster.
- 365 Redewendungen mit Bedeutung, Herkunft und Beispiel; Favoriten, Verlauf der letzten Tage und Suche (auch in den Bedeutungen).
- Widget für den Startbildschirm (Android und iOS).
- Redewendung als Bild teilen.
- Onboarding beim ersten Start, Design Hell/Dunkel/System, Schriftgröße.
- Tippen auf Mitteilung oder Widget öffnet direkt die Detailseite.

## Einrichten

```bash
flutter pub get
flutter test
flutter run
```

Voraussetzungen: Flutter ≥ 3.38.1, iOS ≥ 14.0.

Die Ordner `android/` und `ios/` liegen im Repo und sind maßgeblich.
`tool/setup_platforms.py` war für die erste Einrichtung gedacht; das Widget
legt es nicht an. Das iOS-Widget-Target wurde mit
`tool/add_widget_target.rb` erzeugt.

`./tool/check.sh` führt Analyse, Tests und Debug-Builds für beide Plattformen aus und schreibt alles in `build_log.txt`.

## Vor der Veröffentlichung

1. Bundle-ID ist `bq.p526.rede`, Widget `bq.p526.rede.RedewendixWidget`.
2. iOS: App Group `group.bq.p526.rede` für **Runner** und **RedewendixWidget** in Xcode unter Signing & Capabilities aktivieren.

## Technik

| Bereich | Datei |
|---|---|
| Redewendungen | `assets/idioms.json` |
| Tages-/Slot-Auswahl, Suche, Verlauf | `lib/services/idiom_repository.dart` |
| Zeitplan (rein, getestet) | `lib/services/schedule.dart` |
| Mitteilungen | `lib/services/notification_service.dart` |
| Startbildschirm-Widget (Dart) | `lib/services/widget_service.dart` |
| Widget Android | `android/app/src/main/kotlin/bq/p526/rede/IdiomWidgetProvider.kt` |
| Widget iOS | `ios/RedewendixWidget/RedewendixWidget.swift` |
| Bild teilen | `lib/screens/share_screen.dart` |

Mitteilungen werden im Voraus geplant (max. 60, iOS-Grenze 64): einmal täglich 30 Tage, mehrmals täglich je nach Intervall einige Tage. Beim Öffnen der App wird der Vorrat aufgefüllt; läuft er aus, erinnert eine letzte Mitteilung daran, die App zu öffnen.

Das Widget bekommt die Redewendungen von heute und den nächsten 30 Tagen und wechselt damit um Mitternacht auch ohne geöffnete App.
