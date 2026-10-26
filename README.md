<p align="center">
  <img src="Resources/AppIcon.png" width="112" alt="AClean app icon" />
</p>

<h1 align="center">AClean</h1>

<p align="center">
  <strong>A cleaner, clearer Mac.</strong><br />
  A free, open-source macOS cleaner with menu bar monitoring, junk cleanup, disk analysis, and app removal.
</p>

<p align="center">
  <a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=for-the-badge&logo=github&color=5478f8"></a>
  <a href="LICENSE"><img alt="License: Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=for-the-badge"></a>
  <img alt="Platform: macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=for-the-badge&logo=apple">
  <img alt="Built with Swift" src="https://img.shields.io/badge/built%20with-Swift-f06a35?style=for-the-badge&logo=swift">
</p>

<p align="center">
  <a href="#-explore-aclean">Explore features</a> ·
  <a href="#-get-started">Get started</a> ·
  <a href="#-safety--privacy">Safety & privacy</a> ·
  <a href="#-contribute">Contribute</a>
</p>

<p align="center">
  <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · English · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.fr.md">Français</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a> · <a href="README.it.md">Italiano</a> · <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

---

## ✨ Explore AClean

AClean is a free, open-source Mac cleaning app built with SwiftUI. It brings together macOS junk cleanup, disk space analysis, app uninstalling, and system monitoring, including quick system status from the menu bar dropdown. Review scan results before taking cleanup action.

| Module | What it helps you do |
| --- | --- |
| 🧹 **Smart Cleanup** | Find supported app, developer, and system cache files; review candidates before cleanup. |
| 🗺️ **Space Lens** | Explore disk usage through a visual treemap and inspect large folders. |
| 📦 **Applications** | Review installed apps and related files before uninstalling. |
| ⚡ **Performance** | Inspect supported startup and maintenance opportunities. |
| 📊 **System Status** | Monitor system activity and check system status from the menu bar dropdown. |
| 🩺 **Health Check** | Review a multi-dimension overview of storage, memory, startup, cleanup, and privacy. |


## 🌟 What sets AClean apart

- **Open-source native app.** The SwiftUI app itself is published under Apache-2.0.
- **One Mac-native workspace for several jobs.** Review cleanup candidates, explore disk usage in a visual treemap, inspect app-related files before uninstalling, check overall system health, and glance at system status from the menu bar.
- **Review before cleanup.** Supported candidates and their locations are shown before you confirm a cleanup selection.
- **Built for an international audience.** The app interface and README are available in ten languages.
- **Network behavior is disclosed.** Optional rule updates, weather, and IP-based location use the network; see Safety & privacy and the source for details.

## 📸 Real app screenshots

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean Health Check module" width="500" /><br /><sub>Health Check</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean Clean module" width="500" /><br /><sub>Clean</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean Optimize module" width="500" /><br /><sub>Optimize</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean Applications module" width="500" /><br /><sub>Applications</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean Declutter module" width="500" /><br /><sub>Declutter</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean Status module" width="500" /><br /><sub>Status</sub></td></tr>
</table>


## 🚀 Get started

### Requirements

- macOS 13 or later
- Xcode 16 or later, or Xcode Command Line Tools with Swift 6.0 or later
- Apple Silicon for the current local build configuration

### Build from source

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

Run the repository test suite with:

```bash
./Tests/run_tests.sh
```

Downloadable builds will be listed on [GitHub Releases](https://github.com/letmetodo/aclean-mac/releases) when available.

## 🔐 Privacy, scan scope & deletion

- **Scan scope:** Depending on the module, AClean checks supported local paths for app, browser, and system caches or logs; developer data such as Xcode DerivedData and CoreSimulator; package-manager caches; and installed apps with matching related files. Space Lens creates a local, read-only view of disk usage. Some protected locations require Full Disk Access; without it, results can be incomplete.
- **Review before action:** Cleanup and uninstall previews show candidate names, paths, and sizes so you can inspect and select items before confirming.
- **Recovery:** Ordinary file cleanup and app-removal items are moved to macOS Trash and can generally be restored while they remain there. Emptying Trash, deleting Xcode simulator data, Docker/OrbStack pruning, and some APFS snapshot reclamation can be permanent. Check the action and receipt before confirming.
- **Network requests:** Automatic rule updates are enabled by default and download a manifest and rule database over HTTPS; the host can see the request IP and standard request metadata. Optional weather and IP-location features are off by default. If enabled, location providers can see the request IP; city search sends the entered city and interface language to Open-Meteo, and forecasts send latitude and longitude. Current network requests do not include scan paths, filenames, or cleanup results. System usage readings are displayed locally.

## ⚠️ Known issues & limitations

- The current downloadable build targets Apple Silicon (arm64) and macOS 13 or later.
- The v1.0.0 app has no Apple Developer ID signature or notarization. Gatekeeper may block the first launch; see the release notes and Apple’s [safe-opening guide](https://support.apple.com/en-us/102445).
- Protected locations may be missing from scan results until Full Disk Access is granted. See [open issues](https://github.com/letmetodo/aclean-mac/issues) for currently tracked bugs.
## 🌍 Languages

The interface and this README are available in Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese. Choose a README from the language links above.

## 🛡️ Security reports & feedback

- **Security vulnerabilities:** report them privately through [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new); please do not post vulnerability details in a public issue. See [SECURITY.md](SECURITY.md).
- **Bugs and feature requests:** use [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new). Include the AClean and macOS versions, affected module, steps to reproduce, expected and actual behavior, and logs or screenshots with personal paths and other private data removed.
## 📜 License

AClean is licensed under the [Apache License, Version 2.0](LICENSE).

## 🧭 Project references

Feature and safety-design research consulted [Clean-Me](https://github.com/Kevin-De-Koninck/Clean-Me), [Harbofly](https://github.com/carloshpdoc/Harbofly), [MacSai](https://github.com/iliyami/MacSai), [Mole](https://github.com/tw93/Mole), [Pearcleaner](https://github.com/alienator88/Pearcleaner), [PureMac](https://github.com/momenbasel/PureMac), [ClearDisk](https://github.com/bysiber/cleardisk), [Tencent Lemon Cleaner](https://github.com/Tencent/lemon-cleaner), [Lume](https://github.com/Tyooughtul/lume), [mac-cleaner-cli](https://github.com/guhcostan/mac-cleaner-cli), [mac-cleanup-py](https://github.com/mac-cleanup/mac-cleanup-py), [mac-cleanup-sh](https://github.com/mac-cleanup/mac-cleanup-sh), [Purge](https://github.com/jithin-sabu/purge-app), [Xcode DevCleaner](https://github.com/vashpan/xcode-dev-cleaner), [MacSweep](https://github.com/opencorex-org/macsweep), and [Privacy Guides](https://github.com/sunknudsen/guides). These independent projects are listed as research references; this does not imply endorsement or affiliation. The public release does not intentionally bundle their source code or image assets. AClean's implementation, cleanup rules, and icon are maintained separately. Future contributions that add third-party code or assets must document their origin and license.
