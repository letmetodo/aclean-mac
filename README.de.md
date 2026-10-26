# AClean

**AClean ist ein natives macOS-Werkzeug zum Bereinigen, Analysieren des Speicherplatzes, Entfernen von Apps und Überwachen des Systems.**

Prüfe Scan-Ergebnisse vor Aktionen, analysiere Speicherplatz visuell und kontrolliere zugehörige Dateien beim Entfernen von Apps.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## Intelligente Bereinigung · Space Lens · App-Verwaltung · Live-Monitor

- **Intelligente Bereinigung** — Durchsucht unterstützte App-, Entwickler- und System-Caches und zeigt Kandidaten vor dem Bereinigen.
- **Space Lens** — Erkunde die Speicherbelegung mit einer visuellen Treemap.
- **App-Verwaltung** — Prüfe installierte Apps und zugehörige Dateien vor dem Entfernen.
- **Live-Monitor** — Zeigt Systemaktivitäten und konfigurierbare Menüleisten-Widgets.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.

## Requirements

- macOS 13 oder neuer
- Xcode Command Line Tools mit Swift 6.0 oder neuer (oder Xcode 16 oder neuer)

## Aus dem Quellcode erstellen

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean verwendet Swift und das macOS SDK. Der lokale Build zielt auf Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## Cleanup and privacy

AClean zeigt Fundstücke vor dem Bereinigen an. Prüfe Auswahl und Speicherorte vor der Bestätigung. Das Verhalten hängt von der Version ab; lies den Quellcode und die Release-Hinweise. Optionale Netzwerkfunktionen umfassen Regel-Updates, Wetter und IP-basierte Standortbestimmung. Nicht alle Funktionen sind offline.

## Contributing

Issues und Pull Requests sind willkommen. Bitte nenne macOS- und AClean-Version, Reproduktionsschritte und bereinigte Protokolle ohne persönliche Daten.

## License

Licensed under the [Apache License 2.0](LICENSE).

## Project references

Für Funktions- und Sicherheitsrecherchen wurden Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep und Privacy Guides herangezogen. Dies sind unabhängige Projekte; die Nennung bedeutet keine Empfehlung oder Zugehörigkeit. Implementierung, Bereinigungsregeln und Symbol von AClean werden separat gepflegt. Beiträge mit Drittanbieter-Code oder -Material müssen Herkunft und Lizenz dokumentieren.
