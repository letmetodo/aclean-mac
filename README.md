<p align="center">
  <img src="Resources/AppIcon.png" width="112" alt="AClean app icon" />
</p>

<h1 align="center">AClean</h1>

<p align="center">
  <strong>A cleaner, clearer Mac.</strong><br />
  Native macOS tools for cleanup, disk analysis, app removal, and system monitoring.
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

One native app for the maintenance work that usually gets scattered across separate utilities. AClean is built with SwiftUI and lets you inspect results before taking action.

| Module | What it helps you do |
| --- | --- |
| 🧹 **Smart Cleanup** | Find supported app, developer, and system cache files; review candidates before cleanup. |
| 🗺️ **Space Lens** | Explore disk usage through a visual treemap and inspect large folders. |
| 📦 **Applications** | Review installed apps and related files before uninstalling. |
| ⚡ **Performance** | Inspect supported startup and maintenance opportunities. |
| 📊 **System Status** | Monitor system activity and configure menu bar widgets. |
| 🩺 **Health Check** | Review a multi-dimension overview of storage, memory, startup, cleanup, and privacy. |

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

## 🔐 Safety & privacy

AClean shows scan candidates before cleanup. Review selected items and their locations before confirming an operation. Behavior can vary by version and by the apps and files on your Mac; consult the source and release notes for the version you use.

Some optional features make network requests, including rule updates, weather, and IP-based location. Review the source and in-app settings to see which features use the network. AClean should not be assumed to be entirely offline.

## 🌍 Languages

The interface and this README are available in Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese. Choose a README from the language links above.

## 🤝 Contribute

Issues and pull requests are welcome. Include your macOS and AClean versions, reproduction steps, and relevant logs with personal information removed. Please use GitHub's private vulnerability reporting for security issues when it is enabled for this repository.

If AClean is useful to you, a ⭐ on GitHub helps more Mac users discover the project.

## 📜 License

AClean is licensed under the [Apache License, Version 2.0](LICENSE).

## 🧭 Project references

Feature and safety-design research consulted [Clean-Me](https://github.com/Kevin-De-Koninck/Clean-Me), [Harbofly](https://github.com/carloshpdoc/Harbofly), [MacSai](https://github.com/iliyami/MacSai), [Mole](https://github.com/tw93/Mole), [Pearcleaner](https://github.com/alienator88/Pearcleaner), [PureMac](https://github.com/momenbasel/PureMac), [ClearDisk](https://github.com/bysiber/cleardisk), [Tencent Lemon Cleaner](https://github.com/Tencent/lemon-cleaner), [Lume](https://github.com/Tyooughtul/lume), [mac-cleaner-cli](https://github.com/guhcostan/mac-cleaner-cli), [mac-cleanup-py](https://github.com/mac-cleanup/mac-cleanup-py), [mac-cleanup-sh](https://github.com/mac-cleanup/mac-cleanup-sh), [Purge](https://github.com/jithin-sabu/purge-app), [Xcode DevCleaner](https://github.com/vashpan/xcode-dev-cleaner), [MacSweep](https://github.com/opencorex-org/macsweep), and [Privacy Guides](https://github.com/sunknudsen/guides). These independent projects are listed as research references; this does not imply endorsement or affiliation. The public release does not intentionally bundle their source code or image assets. AClean's implementation, cleanup rules, and icon are maintained separately. Future contributions that add third-party code or assets must document their origin and license.
