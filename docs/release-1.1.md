# Redewendix 1.1 – Veröffentlichung

1.1 bringt Werbung in der kostenlosen Version und den einmaligen Kauf
**Redewendix Pro** (2,99 €). Diese Liste ergänzt die Build-Checkliste.

## 1. Store-Produkte

| Store | Wo | Einstellung |
|---|---|---|
| App Store Connect | App → In-App-Käufe | Typ *Nicht verbrauchbar*, Produkt-ID `bq.p526.rede.pro`, Preis 2,99 €, Name „Redewendix Pro“, Screenshot der Pro-Seite für die Prüfung |
| Play Console | Monetarisieren → In-App-Produkte | Produkt-ID `bq.p526.rede.pro`, 2,99 €, aktivieren |

- Apple: Vertrag für kostenpflichtige Apps (Paid Apps Agreement), Bank- und Steuerdaten müssen aktiv sein.
- Testen: iOS mit Sandbox-Tester (Einstellungen → App Store → Sandbox-Account), Android mit Lizenztester in einem internen Test-Track.

## 2. AdMob

1. Zwei Apps anlegen: Android (`bq.p526.rede`) und iOS.
2. Je einen Anzeigenblock **Banner** und **Interstitial** anlegen.
3. IDs eintragen:
   - Anzeigenblöcke → `lib/config.dart` (`kAdBannerAndroid`, `kAdBannerIos`, `kAdInterstitialAndroid`, `kAdInterstitialIos`)
   - App-ID Android → `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
   - App-ID iOS → `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
4. Datenschutz & Nachrichten → **DSGVO-Nachricht** erstellen und veröffentlichen; für iOS die **IDFA-Erklärung** aktivieren.
5. `app-ads.txt` mit der Zeile aus AdMob auf die Entwickler-Website legen (dieselbe Domain wie im Store-Eintrag).

Solange in `lib/config.dart` keine echten Anzeigenblock-IDs stehen, zeigen Release-Builds **keine** Werbung. Debug-Builds zeigen immer Googles Test-Anzeigen.

## 3. Store-Angaben ändern

**Google Play**
- App-Inhalte → Werbung: **Ja, enthält Werbung**.
- Datensicherheit: Gerätekennungen oder andere IDs (Werbe-ID), App-Interaktionen, Absturzprotokolle/Diagnose – *erhoben*, *mit Dritten geteilt* (Google AdMob), Zweck *Werbung/Marketing* und *Analysen*; Übertragung verschlüsselt. Käufe laufen über Google Play.
- Zielgruppe: keine Altersgruppe unter 13 wählen (sonst gelten die Familien-Richtlinien für Werbung).

**App Store**
- App-Datenschutz: *Kennungen → Geräte-ID* und *Nutzungsdaten → Produktinteraktion, Werbedaten* für **Werbung von Drittanbietern**; *Diagnose* optional. „Tracking“ nur angeben, wenn die IDFA-Erklärung aktiv ist.
- Altersfreigabe: Die App fordert nur Anzeigen bis Einstufung *PG* an (im Code gesetzt). Zusätzlich in AdMob → Blockierungseinstellungen → Anzeigeninhalte *PG* als Maximum wählen.

## 4. Datenschutzerklärung

Der Entwurf in [`datenschutz-1.1.md`](datenschutz-1.1.md) ersetzt den bisherigen Abschnitt „keine Daten“. Bitte prüfen (kein Rechtsrat) und auf der Website veröffentlichen, **bevor** 1.1 live geht.

## 5. „Neu in Version 1.1“

```
Neu in Redewendix 1.1:
• Redewendix Pro – einmal kaufen, kein Abo:
  – keine Werbung
  – mehrmals täglich eine neue Redewendung
  – Quiz und Lernstatistik im neuen Tab „Lernen“
  – Zusatz-Pakete: Sprichwörter und Geflügelte Worte
• Die kostenlose Version bleibt vollständig nutzbar und zeigt dezente Werbung.
• Wer „Mehrmals täglich“ schon genutzt hat, behält es auch ohne Pro.
```

## 6. Vor dem Hochladen testen

- [ ] Einwilligungs-Dialog erscheint nach dem Onboarding (in der EU)
- [ ] Banner auf Detailseite und „Alle“, nicht auf Heute/Favoriten/Einstellungen
- [ ] Vollbild-Anzeige erst am zweiten Tag, nach 3 geöffneten Redewendungen, höchstens einmal am Tag
- [ ] Pro kaufen (Sandbox) → Werbung sofort weg, „Mehrmals täglich“, Quiz und Pakete offen
- [ ] App löschen, neu installieren, „Käufe wiederherstellen“ → Pro wieder aktiv
- [ ] Einstellungen → „Datenschutz-Einstellungen“ öffnet den Einwilligungs-Dialog
- [ ] Release-Build mit echten IDs zeigt echte Anzeigen (nicht selbst anklicken!)
