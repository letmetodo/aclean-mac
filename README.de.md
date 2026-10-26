<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean ist ein natives macOS-Werkzeug zum Bereinigen, Analysieren des Speicherplatzes, Entfernen von Apps und Überwachen des Systems.**

Prüfe Scan-Ergebnisse vor Aktionen, analysiere Speicherplatz visuell und kontrolliere zugehörige Dateien beim Entfernen von Apps.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ Intelligente Bereinigung · Space Lens · App-Verwaltung · Live-Monitor

- **Intelligente Bereinigung** — Durchsucht unterstützte App-, Entwickler- und System-Caches und zeigt Kandidaten vor dem Bereinigen.
- **Space Lens** — Erkunde die Speicherbelegung mit einer visuellen Treemap.
- **App-Verwaltung** — Prüfe installierte Apps und zugehörige Dateien vor dem Entfernen.
- **Live-Monitor** — Zeigt Systemaktivitäten und konfigurierbare Menüleisten-Widgets.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.


## 🌟 Was AClean auszeichnet

- **Die native App selbst ist Open Source.** ACleans SwiftUI-App steht unter Apache-2.0. Projekte unterscheiden sich darin, was sie veröffentlichen: Die Mole-Dokumentation trennt die kostenlose Open-Source-CLI von der kostenpflichtigen Mac-App, deren Quellcode nicht im öffentlichen Repository enthalten ist ([Mole for Mac](https://github.com/tw93/Mole-App)).
- **Mehrere Aufgaben in einer nativen App.** Bereinigungskandidaten prüfen, Speicherplatz in einer visuellen Treemap erkunden, zugehörige Dateien vor einer App-Deinstallation ansehen, den Systemzustand prüfen und den Status über die Menüleiste aufrufen.
- **Erst prüfen, dann bereinigen.** AClean zeigt unterstützte Kandidaten und ihre Speicherorte, bevor du die Auswahl bestätigst.
- **Zehn Sprachen.** App-Oberfläche und README sind in zehn Sprachen verfügbar.
- **Netzwerkzugriffe werden offengelegt.** Optionale Regelupdates, Wetter und IP-basierte Standortbestimmung verwenden das Netzwerk. Details stehen unter „Bereinigung und Datenschutz“ und im Quellcode.

## 📸 Echte App-Ansichten

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean Systemcheck module" width="500" /><br /><sub>Systemcheck</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean Bereinigung module" width="500" /><br /><sub>Bereinigung</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean Optimierung module" width="500" /><br /><sub>Optimierung</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean Apps module" width="500" /><br /><sub>Apps</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean Ordnen module" width="500" /><br /><sub>Ordnen</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean Systemstatus module" width="500" /><br /><sub>Systemstatus</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 oder neuer
- Xcode Command Line Tools mit Swift 6.0 oder neuer (oder Xcode 16 oder neuer)

## Aus dem Quellcode erstellen

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean verwendet Swift und das macOS SDK. Der lokale Build zielt auf Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 Cleanup and privacy

AClean zeigt Fundstücke vor dem Bereinigen an. Prüfe Auswahl und Speicherorte vor der Bestätigung. Das Verhalten hängt von der Version ab; lies den Quellcode und die Release-Hinweise. Optionale Netzwerkfunktionen umfassen Regel-Updates, Wetter und IP-basierte Standortbestimmung. Nicht alle Funktionen sind offline.

## 🤝 Contributing

Issues und Pull Requests sind willkommen. Bitte nenne macOS- und AClean-Version, Reproduktionsschritte und bereinigte Protokolle ohne persönliche Daten.

## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

Für Funktions- und Sicherheitsrecherchen wurden Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep und Privacy Guides herangezogen. Dies sind unabhängige Projekte; die Nennung bedeutet keine Empfehlung oder Zugehörigkeit. Implementierung, Bereinigungsregeln und Symbol von AClean werden separat gepflegt. Beiträge mit Drittanbieter-Code oder -Material müssen Herkunft und Lizenz dokumentieren.
