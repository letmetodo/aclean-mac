<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**原生 macOS 清理、磁碟分析、應用程式移除與系統監控工具。**

AClean 將日常 Mac 維護功能整合於 SwiftUI App。清理前可檢視掃描結果，以視覺化方式分析磁碟空間，並在解除安裝 App 時檢查相關檔案。

語言： [简体中文](README.zh-CN.md) · [English](README.md) · 繁體中文 · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ 功能

- **智慧清理**：掃描支援的應用程式、開發工具與系統快取位置，並在清理前檢查候選項目。
- **空間透鏡**：透過視覺化矩形樹圖檢視磁碟空間使用情況。
- **應用程式管理**：移除前檢查已安裝 App 與相關檔案。
- **即時監控**：檢視系統活動並設定選單列元件。

## 軟體實機畫面

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean 健康檢查 module" width="500" /><br /><sub>健康檢查</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean 垃圾清理 module" width="500" /><br /><sub>垃圾清理</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean 效能最佳化 module" width="500" /><br /><sub>效能最佳化</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean 應用程式 module" width="500" /><br /><sub>應用程式</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean 空間透鏡 module" width="500" /><br /><sub>空間透鏡</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean 整理雜亂 module" width="500" /><br /><sub>整理雜亂</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean 系統狀態 module" width="500" /><br /><sub>系統狀態</sub></td></tr>
</table>


## 🧰 系統需求

- macOS 13 或更新版本
- Xcode Command Line Tools 與 Swift 6.0 或更新版本（或 Xcode 16 或更新版本）

## 🚀 從原始碼建置

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

本 App 使用 Swift 與 macOS SDK 編寫，本機建置目標為 Apple Silicon。可下載版本發布後會列於 [Releases](https://github.com/letmetodo/aclean-mac/releases)。

## 🔐 清理與隱私

AClean 會先顯示掃描候選項目。確認操作前，請檢查所選項目及其位置。特定版本的行為請參閱對應原始碼與發布說明；掃描結果會依 Mac 上安裝的 App 與檔案而異。應用程式包含規則更新、天氣及 IP 定位等選用網路功能。請查看原始碼與 App 內設定，瞭解網路請求。

## 🤝 貢獻

歡迎提交 Issue 與 Pull Request。請提供 macOS 和 AClean 版本、重現步驟，以及已移除個人資料的相關記錄。請勿公開發布安全漏洞；若已啟用 GitHub 私密漏洞回報，請使用該管道。

## 📜 授權條款

本專案採用 [Apache License 2.0](LICENSE)。

## 🧭 專案參考

功能與安全設計研究參考了多個獨立開源專案，包括 Clean-Me、Harbofly、MacSai、Mole、Pearcleaner、PureMac、ClearDisk、Tencent Lemon Cleaner、Lume、mac-cleaner-cli、mac-cleanup-py、mac-cleanup-sh、Purge、Xcode DevCleaner、MacSweep 與 Privacy Guides。此列表僅記錄研究參考，不代表認可或關聯。AClean 發布內容不會刻意包含上游原始碼或圖片；若未來貢獻加入第三方程式碼或資源，必須記錄來源與授權條款。
