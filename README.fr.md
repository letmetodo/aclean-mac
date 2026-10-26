<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean est un utilitaire macOS natif pour le nettoyage, l’analyse du disque, la désinstallation d’apps et le suivi du système.**

Examinez les résultats avant toute action, visualisez l’espace disque et inspectez les fichiers associés lors de la désinstallation.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ Nettoyage intelligent · Space Lens · Gestion des apps · Moniteur en direct

- **Nettoyage intelligent** — Analyse les caches pris en charge des apps, outils de développement et du système, puis présente les éléments avant nettoyage.
- **Space Lens** — Explorez l’espace disque avec une arborescence visuelle.
- **Gestion des apps** — Inspectez les apps installées et leurs fichiers associés avant suppression.
- **Moniteur en direct** — Consultez l’activité système et configurez les widgets de la barre des menus.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.


## 🌟 Ce qui distingue AClean

- **L’application native elle-même est open source.** L’app SwiftUI d’AClean est publiée sous Apache-2.0 et peut être examinée, modifiée et redistribuée.
- **Plusieurs usages dans une seule app native.** Examinez les éléments à nettoyer, explorez le disque avec une arborescence visuelle, vérifiez les fichiers associés avant de désinstaller une app, consultez l’état général du système et affichez rapidement son statut depuis la barre des menus.
- **Vérifier avant de nettoyer.** AClean affiche les éléments pris en charge et leur emplacement avant de confirmer la sélection.
- **Dix langues.** L’interface et le README sont disponibles en dix langues.
- **Les connexions réseau sont indiquées.** Les mises à jour de règles, la météo et la localisation par IP sont des fonctions facultatives qui utilisent le réseau ; consultez « Nettoyage et confidentialité » et le code source.

## 📸 Captures réelles de l’application

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean Bilan de santé module" width="500" /><br /><sub>Bilan de santé</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean Nettoyage module" width="500" /><br /><sub>Nettoyage</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean Optimisation module" width="500" /><br /><sub>Optimisation</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean Applications module" width="500" /><br /><sub>Applications</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean Organisation module" width="500" /><br /><sub>Organisation</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean État du système module" width="500" /><br /><sub>État du système</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 ou ultérieur
- Xcode Command Line Tools avec Swift 6.0 ou ultérieur (ou Xcode 16 ou ultérieur)

## Compiler depuis les sources

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean est écrit en Swift avec le SDK macOS. La compilation locale cible Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 Confidentialité, périmètre d’analyse et suppression

- **Périmètre:** selon le module, AClean examine les chemins locaux pris en charge par ses règles : caches et journaux d’apps, de navigateurs et du système ; données de développement comme Xcode DerivedData/CoreSimulator ; caches de gestionnaires de paquets ; apps installées et fichiers associés identifiés. Space Lens affiche l’espace disque local en lecture seule. Certains emplacements protégés exigent l’Accès complet au disque ; sans cette autorisation, les résultats peuvent être incomplets.
- **Avant l’action:** l’aperçu du nettoyage et de la désinstallation affiche le nom, le chemin et la taille des éléments proposés afin de vérifier la sélection avant confirmation.
- **Restauration:** les fichiers ordinaires nettoyés et les fichiers associés aux apps sont déplacés vers la Corbeille macOS et peuvent généralement être restaurés tant qu’ils s’y trouvent. Vider la Corbeille, supprimer des données de simulateur Xcode, lancer Docker/OrbStack prune et certaines récupérations d’instantanés APFS peuvent être irréversibles. Vérifiez le type d’action et le reçu avant de confirmer.
- **Réseau:** la mise à jour automatique des règles est activée par défaut et télécharge un manifeste et une base de règles via HTTPS ; le serveur voit l’adresse IP de la requête et les métadonnées réseau habituelles. Les fonctions météo et localisation IP sont désactivées par défaut. Si elles sont activées, les fournisseurs de localisation voient l’IP ; la recherche de ville envoie le texte saisi et la langue de l’interface à Open-Meteo, et les prévisions envoient latitude et longitude. Les requêtes actuelles n’incluent ni chemins analysés, ni noms de fichiers, ni résultats de nettoyage. Les métriques système sont affichées localement.

## ⚠️ Problèmes connus et limites

- Le téléchargement actuel cible Apple Silicon (arm64) et nécessite macOS 13 ou une version ultérieure.
- L’app v1.0.0 n’a pas de signature Apple Developer ID ni de notarisation. Gatekeeper peut bloquer le premier lancement ; consultez les notes de version et le [guide Apple pour ouvrir une app en toute sécurité](https://support.apple.com/en-us/102445).
- Sans Accès complet au disque, certains emplacements protégés ne peuvent pas être analysés complètement. Les bugs suivis figurent dans [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues).
## 🛡️ Signaler une vulnérabilité et envoyer un retour

- **Vulnérabilités de sécurité :** signalez-les en privé via [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new). Ne publiez pas les détails dans une issue publique. Consultez [SECURITY.md](SECURITY.md).
- **Bugs et suggestions :** utilisez [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new) et indiquez les versions d’AClean et de macOS, le module concerné, les étapes de reproduction, le résultat attendu et observé, ainsi que des journaux ou captures sans chemins personnels ni données privées.
## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

Les recherches sur les fonctionnalités et la sécurité ont consulté Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep et Privacy Guides. Ces projets sont indépendants ; cette liste ne signifie ni approbation ni affiliation. Le code, les règles de nettoyage et l’icône d’AClean sont maintenus séparément. Toute future contribution ajoutant du code ou des ressources tierces doit en documenter la provenance et la licence.
