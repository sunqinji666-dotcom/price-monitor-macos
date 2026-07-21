# Preismonitor

> Lokales macOS-Werkzeug für Preise und Lagerbestand ausgewählter Shops sowie WOYAO-API-Guthaben und aktuelle Nutzung in der Menüleiste.

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Deutsch**

## Funktionen

- Gruppiert vergleichbare Produkte und sortiert sie nach dem niedrigsten Preis.
- Prüft Shops jede Minute und meldet neue Artikel oder Nachschub per macOS-Sprachausgabe.
- Zeigt das aktuelle WOYAO-Guthaben direkt in der Menüleiste.
- Aktualisiert die Nutzung stündlich und spricht Guthaben, verbrauchtes Kontingent und Tageskosten.
- Listet die letzten zehn Aufrufe mit Modell, Kosten, Tokens und Zeit.

## Schnellstart

1. Laden Sie `PriceMonitor-v1.4-macOS-arm64.zip` über [Releases](../../releases/latest) herunter, entpacken Sie es und verschieben Sie die App nach Programme.
2. Öffnen Sie die App einmal. Für den Start bei der Anmeldung installieren Sie die Benutzervorlage `LaunchAgent.plist`.
3. Öffnen Sie **WOYAO-Nutzung**, fügen Sie Ihren API Key ein und wählen Sie **In Dokumente speichern und lesen**.

## Datenschutz

Shopdaten werden aus öffentlichen APIs gelesen. Der WOYAO-Key wird nur in `Documents/价格监控/woyao-api-key.txt` gespeichert und nie in Git, normalen Logs oder Browserdaten abgelegt. Synchronisieren Sie diese Klartextdatei nicht in einen öffentlichen Cloudspeicher.

## Build und Lizenz

Erforderlich sind macOS, Xcode Command Line Tools und Swift 6. Mit `./build_app.sh` wird `价格监控.app` erstellt.

Dieses Projekt steht unter der [MIT License](../LICENSE).
