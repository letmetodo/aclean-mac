<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean è un’utilità macOS nativa per pulizia, analisi del disco, rimozione delle app e monitoraggio del sistema.**

Esamina i risultati prima di agire, visualizza l’uso del disco e controlla i file correlati quando disinstalli un’app.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ Pulizia intelligente · Space Lens · Gestione app · Monitoraggio live

- **Pulizia intelligente** — Analizza le cache supportate di app, strumenti di sviluppo e sistema, mostrando gli elementi prima della pulizia.
- **Space Lens** — Esplora lo spazio su disco con una mappa ad albero visuale.
- **Gestione app** — Controlla le app installate e i relativi file prima della rimozione.
- **Monitoraggio live** — Visualizza l’attività di sistema e configura i widget nella barra dei menu.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.


## 🌟 Cosa distingue AClean

- **L’app nativa stessa è open source.** L’app SwiftUI di AClean è pubblicata con licenza Apache-2.0 ed è disponibile per verifica, modifica e ridistribuzione.
- **Più attività in un’unica app nativa.** Esamina gli elementi da pulire, esplora il disco con una mappa ad albero visuale, controlla i file correlati prima di disinstallare un’app, consulta lo stato generale del sistema e visualizzalo rapidamente dalla barra dei menu.
- **Prima controlli, poi pulisci.** AClean mostra gli elementi supportati e i relativi percorsi prima di confermare la selezione.
- **Dieci lingue.** L’interfaccia dell’app e il README sono disponibili in dieci lingue.
- **Trasparenza sull’uso della rete.** Gli aggiornamenti facoltativi delle regole, il meteo e la geolocalizzazione tramite IP usano la rete. Consulta “Pulizia e privacy” e il codice sorgente per i dettagli.

## 📸 Schermate reali dell’app

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean Controllo salute module" width="500" /><br /><sub>Controllo salute</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean Pulizia module" width="500" /><br /><sub>Pulizia</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean Ottimizzazione module" width="500" /><br /><sub>Ottimizzazione</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean Applicazioni module" width="500" /><br /><sub>Applicazioni</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean Organizzazione module" width="500" /><br /><sub>Organizzazione</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean Stato del sistema module" width="500" /><br /><sub>Stato del sistema</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 o successivo
- Xcode Command Line Tools con Swift 6.0 o successivo (oppure Xcode 16 o successivo)

## Compilazione dal sorgente

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean è scritto in Swift e usa il macOS SDK. La compilazione locale è destinata ad Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 Privacy, ambito di scansione ed eliminazione

- **Ambito:** a seconda del modulo, AClean controlla i percorsi locali supportati dalle regole: cache e log di app, browser e sistema; dati di sviluppo come Xcode DerivedData/CoreSimulator; cache dei gestori di pacchetti; app installate e file correlati identificati. Space Lens mostra localmente l’uso del disco in sola lettura. Alcune posizioni protette richiedono Accesso completo al disco; senza autorizzazione i risultati possono essere incompleti.
- **Prima dell’azione:** le anteprime di pulizia e disinstallazione mostrano nome, percorso e dimensione degli elementi, così puoi controllare la selezione prima di confermare.
- **Ripristino:** i normali file di pulizia e i file associati alle app vengono spostati nel Cestino di macOS e in genere possono essere ripristinati finché vi rimangono. Svuotare il Cestino, eliminare dati dei simulatori Xcode, eseguire Docker/OrbStack prune e alcune operazioni sugli snapshot APFS possono essere permanenti. Controlla il tipo di azione e il resoconto prima di confermare.
- **Rete:** gli aggiornamenti automatici delle regole sono attivi per impostazione predefinita e scaricano via HTTPS un manifesto e il database delle regole; il server vede l’IP della richiesta e i normali metadati di rete. Meteo e posizione IP sono disattivati per impostazione predefinita. Se attivati, i provider di posizione vedono l’IP; la ricerca città invia testo e lingua dell’interfaccia a Open-Meteo, mentre le previsioni inviano latitudine e longitudine. Le richieste attuali non includono percorsi scansionati, nomi di file o risultati della pulizia. Le metriche di sistema sono mostrate localmente.

## ⚠️ Problemi noti e limitazioni

- Il download attuale è solo per Apple Silicon (arm64) e richiede macOS 13 o successivo.
- L’app v1.0.0 non ha firma Apple Developer ID né notarizzazione. Gatekeeper può bloccare il primo avvio; consulta le note di rilascio e la [guida Apple per aprire le app in sicurezza](https://support.apple.com/en-us/102445).
- Senza Accesso completo al disco, alcune posizioni protette potrebbero non essere analizzate completamente. I bug attualmente tracciati sono in [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues).
## 🛡️ Segnalazioni di sicurezza e feedback

- **Vulnerabilità:** segnalale in privato tramite [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new). Non pubblicare dettagli in una issue pubblica. Consulta [SECURITY.md](SECURITY.md).
- **Bug e suggerimenti:** usa [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new). Indica versioni di AClean e macOS, modulo interessato, passaggi per riprodurre, risultato atteso ed effettivo, e log o schermate senza percorsi personali o dati privati.
## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

La ricerca su funzioni e sicurezza ha consultato Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep e Privacy Guides. Sono progetti indipendenti; l’elenco non implica approvazione o affiliazione. Implementazione, regole di pulizia e icona di AClean sono mantenute separatamente. Ogni contributo futuro con codice o risorse di terzi deve documentarne provenienza e licenza.
