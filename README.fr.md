# AClean

**AClean est un utilitaire macOS natif pour le nettoyage, l’analyse du disque, la désinstallation d’apps et le suivi du système.**

Examinez les résultats avant toute action, visualisez l’espace disque et inspectez les fichiers associés lors de la désinstallation.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## Nettoyage intelligent · Space Lens · Gestion des apps · Moniteur en direct

- **Nettoyage intelligent** — Analyse les caches pris en charge des apps, outils de développement et du système, puis présente les éléments avant nettoyage.
- **Space Lens** — Explorez l’espace disque avec une arborescence visuelle.
- **Gestion des apps** — Inspectez les apps installées et leurs fichiers associés avant suppression.
- **Moniteur en direct** — Consultez l’activité système et configurez les widgets de la barre des menus.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.

## Requirements

- macOS 13 ou ultérieur
- Xcode Command Line Tools avec Swift 6.0 ou ultérieur (ou Xcode 16 ou ultérieur)

## Compiler depuis les sources

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean est écrit en Swift avec le SDK macOS. La compilation locale cible Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## Cleanup and privacy

AClean affiche les éléments détectés avant le nettoyage. Vérifiez les éléments sélectionnés et leur emplacement avant de confirmer. Consultez le code et les notes de version pour connaître le comportement d’une version donnée. Certaines fonctions réseau sont facultatives, notamment les mises à jour des règles, la météo et la localisation par IP.

## Contributing

Les issues et pull requests sont les bienvenues. Indiquez les versions de macOS et d’AClean, les étapes de reproduction et des journaux expurgés de données personnelles.

## License

Licensed under the [Apache License 2.0](LICENSE).

## Project references

Les recherches sur les fonctionnalités et la sécurité ont consulté Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep et Privacy Guides. Ces projets sont indépendants ; cette liste ne signifie ni approbation ni affiliation. Le code, les règles de nettoyage et l’icône d’AClean sont maintenus séparément. Toute future contribution ajoutant du code ou des ressources tierces doit en documenter la provenance et la licence.
