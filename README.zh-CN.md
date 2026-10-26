<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>免费开源的 macOS 清理软件：菜单栏下拉监控、垃圾清理、磁盘空间分析与应用卸载。</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean 是一款免费开源的 Mac 清理软件，提供菜单栏下拉系统监控、macOS 垃圾清理、磁盘空间分析与应用卸载功能。**

AClean 将日常 Mac 维护功能整合在 SwiftUI 应用中。清理前可查看扫描结果，使用可视化方式分析磁盘空间，并在卸载应用时检查相关文件。

语言：简体中文 · [English](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ 功能

- **智能清理**：扫描支持的应用、开发工具和系统缓存位置，清理前检查候选项。
- **空间透镜**：通过可视化矩形树图查看磁盘空间占用。
- **应用管理**：卸载前检查已安装应用及其关联文件。
- **实时监控**：查看系统活动，并通过菜单栏下拉面板快速查看系统状态。
- **多语言界面**：简体中文、繁体中文、英语、日语、韩语、法语、德语、西班牙语、意大利语和巴西葡萄牙语。


## 🌟 AClean 的项目亮点

- **开源的是原生 App 本身。** AClean 的 SwiftUI 应用采用 Apache-2.0 许可证公开。不同项目的开源范围并不相同：Mole 的文档将免费开源 CLI 与独立的付费 Mac App 区分开来，其公开仓库不包含 Mac App 源码（[Mole for Mac](https://github.com/tw93/Mole-App)）。
- **一个原生界面覆盖多种日常任务。** 在同一款 App 中预览清理候选项、用可视化矩形树图分析磁盘、卸载前检查应用关联文件、查看系统健康概况，并从菜单栏快速查看系统状态。
- **先检查，再清理。** 确认清理前，AClean 会展示支持清理的候选项及其位置，供你检查选择。
- **面向多语言用户。** App 界面和 README 均提供十种语言。
- **明确说明联网行为。** 可选的规则更新、天气和 IP 定位功能会使用网络；详情见“清理与隐私”及源代码。

## 软件实机截图

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean 健康检查 module" width="500" /><br /><sub>健康检查</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean 垃圾清理 module" width="500" /><br /><sub>垃圾清理</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean 性能优化 module" width="500" /><br /><sub>性能优化</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean 应用程序 module" width="500" /><br /><sub>应用程序</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean 空间透镜 module" width="500" /><br /><sub>空间透镜</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean 整理杂乱 module" width="500" /><br /><sub>整理杂乱</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean 系统状态 module" width="500" /><br /><sub>系统状态</sub></td></tr>
</table>


## 🧰 系统要求

- macOS 13 或更高版本
- Xcode Command Line Tools，Swift 6.0 或更高版本（或 Xcode 16 或更高版本）

## 🚀 从源码构建

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

应用使用 Swift 和 macOS SDK 编写。本地构建面向 Apple Silicon。可下载版本发布后会列在 [Releases](https://github.com/letmetodo/aclean-mac/releases)。

运行测试套件：

```bash
./Tests/run_tests.sh
```

## 🔐 清理与隐私

AClean 会先展示扫描候选项。确认操作前，请检查已选项目及其位置。具体版本的行为请以对应源码和发布说明为准；扫描结果取决于 Mac 上安装的应用和文件。

应用包含可选的联网功能，例如规则更新、天气和基于 IP 的位置查询。请查看源码和应用内设置，了解哪些功能会发起网络请求；不要假设所有功能都仅在本地运行。

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request。请附上 macOS 与 AClean 版本、复现步骤，以及已移除个人信息的相关日志。请勿公开发布安全漏洞；如本仓库启用了 GitHub 私密漏洞报告，请通过该渠道提交。

## 📜 许可证

本项目采用 [Apache License 2.0](LICENSE)。

## 🧭 项目参考

功能与安全设计研究参考了 [Clean-Me](https://github.com/Kevin-De-Koninck/Clean-Me)、[Harbofly](https://github.com/carloshpdoc/Harbofly)、[MacSai](https://github.com/iliyami/MacSai)、[Mole](https://github.com/tw93/Mole)、[Pearcleaner](https://github.com/alienator88/Pearcleaner)、[PureMac](https://github.com/momenbasel/PureMac)、[ClearDisk](https://github.com/bysiber/cleardisk)、[Tencent Lemon Cleaner](https://github.com/Tencent/lemon-cleaner)、[Lume](https://github.com/Tyooughtul/lume)、[mac-cleaner-cli](https://github.com/guhcostan/mac-cleaner-cli)、[mac-cleanup-py](https://github.com/mac-cleanup/mac-cleanup-py)、[mac-cleanup-sh](https://github.com/mac-cleanup/mac-cleanup-sh)、[Purge](https://github.com/jithin-sabu/purge-app)、[Xcode DevCleaner](https://github.com/vashpan/xcode-dev-cleaner)、[MacSweep](https://github.com/opencorex-org/macsweep) 和 [Privacy Guides](https://github.com/sunknudsen/guides)。这些是独立项目，此列表仅记录研究参考，不代表认可或关联。AClean 发布内容不会有意包含上游源码仓库或图片资源；实现、清理规则与图标均在本仓库单独维护。未来若贡献中加入第三方代码或资源，必须同时记录其来源与许可证。
