# Redewendix (p526)

Jeden Tag eine deutsche Redewendung auf dem Sperrbildschirm.

- **Komplett kostenlos, ohne Werbung.** Einmal täglich zu einer wählbaren Uhrzeit oder mehrmals täglich (bis stündlich) in einem eigenen Zeitfenster.
- Favoriten, Suche über alle Redewendungen, Detailseite mit Bedeutung, Herkunft und Beispiel.
- Tippen auf die Mitteilung öffnet direkt die Detailseite.

## Einrichten

```bash
python3 tool/setup_platforms.py   # erzeugt android/ + ios/ und trägt alles ein
flutter test
flutter run
```

Voraussetzung: Flutter ≥ 3.38.1.

## Vor der Veröffentlichung

1. Bundle-ID ist `bq.p526.rede` (Konstante `BUNDLE_ID` in `tool/setup_platforms.py`).

## Technik

| Bereich | Datei |
|---|---|
| Redewendungen (118) | `assets/idioms.json` |
| Tages-/Slot-Auswahl | `lib/services/idiom_repository.dart` |
| Zeitplan (rein, getestet) | `lib/services/schedule.dart` |
| Mitteilungen | `lib/services/notification_service.dart` |

Mitteilungen werden im Voraus geplant (max. 60, iOS-Grenze 64): einmal täglich 30 Tage, mehrmals täglich je nach Intervall einige Tage. Beim Öffnen der App wird der Vorrat aufgefüllt; läuft er aus, erinnert eine letzte Mitteilung daran, die App zu öffnen.
