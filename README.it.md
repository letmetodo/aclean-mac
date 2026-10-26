# AClean

**AClean è un’utilità macOS nativa per pulizia, analisi del disco, rimozione delle app e monitoraggio del sistema.**

Esamina i risultati prima di agire, visualizza l’uso del disco e controlla i file correlati quando disinstalli un’app.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## Pulizia intelligente · Space Lens · Gestione app · Monitoraggio live

- **Pulizia intelligente** — Analizza le cache supportate di app, strumenti di sviluppo e sistema, mostrando gli elementi prima della pulizia.
- **Space Lens** — Esplora lo spazio su disco con una mappa ad albero visuale.
- **Gestione app** — Controlla le app installate e i relativi file prima della rimozione.
- **Monitoraggio live** — Visualizza l’attività di sistema e configura i widget nella barra dei menu.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.

## Requirements

- macOS 13 o successivo
- Xcode Command Line Tools con Swift 6.0 o successivo (oppure Xcode 16 o successivo)

## Compilazione dal sorgente

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean è scritto in Swift e usa il macOS SDK. La compilazione locale è destinata ad Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## Cleanup and privacy

AClean mostra gli elementi rilevati prima della pulizia. Controlla la selezione e i percorsi prima di confermare. Consulta il sorgente e le note di rilascio per il comportamento della versione specifica. Sono disponibili funzioni di rete opzionali, tra cui aggiornamenti delle regole, meteo e posizione basata su IP. Non tutte le funzioni sono necessariamente offline.

## Contributing

Issue e pull request sono benvenute. Indica le versioni di macOS e AClean, i passaggi per riprodurre il problema e i log senza informazioni personali.

## License

Licensed under the [Apache License 2.0](LICENSE).

## Project references

La ricerca su funzioni e sicurezza ha consultato Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep e Privacy Guides. Sono progetti indipendenti; l’elenco non implica approvazione o affiliazione. Implementazione, regole di pulizia e icona di AClean sono mantenute separatamente. Ogni contributo futuro con codice o risorse di terzi deve documentarne provenienza e licenza.
