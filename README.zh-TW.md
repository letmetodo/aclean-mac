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


## 🌟 AClean 的特色

- **原生 App 本身開源。** AClean 的 SwiftUI App 採用 Apache-2.0 授權公開，方便使用者檢視、修改與再散布。
- **一個原生介面整合多種日常工作。** 在同一個 App 中預覽清理候選項、以視覺化矩形樹圖分析磁碟、在解除安裝前檢查應用程式關聯檔案、查看系統健康概況，並從選單列快速查看系統狀態。
- **先檢視，再清理。** 確認清理前，AClean 會列出支援清理的候選項及其位置，方便檢查選取內容。
- **服務多語言使用者。** App 介面與 README 均提供十種語言。
- **清楚揭露網路使用情況。** 可選的規則更新、天氣和 IP 定位功能會使用網路；詳情請參閱「清理與隱私」及原始碼。

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

## 🔐 隱私、掃描範圍與刪除

- **掃描範圍：** 不同模組會檢查規則支援的本機位置，包括 App、瀏覽器與系統快取或日誌、Xcode DerivedData/CoreSimulator 等開發資料、套件管理器快取，以及已安裝 App 和可匹配的關聯檔案。Space Lens 會在本機唯讀呈現磁碟使用情況。部分受保護位置需要「完全磁碟取用權限」；未授予時，結果可能不完整。
- **操作前預覽：** 清理與解除安裝預覽會顯示候選項名稱、路徑和大小，供你檢查、選取後再確認。
- **是否可還原：** 一般檔案清理與 App 解除安裝關聯檔案會移至 macOS 垃圾桶；只要仍在垃圾桶中，通常可以還原。清空垃圾桶、刪除 Xcode 模擬器資料、Docker/OrbStack 清理，以及部分 APFS 快照回收可能無法還原。確認前請檢查操作類型與回執。
- **網路傳輸：** 規則更新預設為自動啟用，會透過 HTTPS 下載規則清單與資料庫；伺服器可看到請求 IP 與一般請求中繼資料。天氣與 IP 定位等選用網路功能預設關閉。啟用後，定位服務會看到請求 IP；城市搜尋會將輸入的城市名稱與介面語言傳送至 Open-Meteo，天氣預報請求會傳送緯度與經度。目前網路請求不包含掃描路徑、檔名或清理結果；系統用量資料在本機顯示。

## ⚠️ 已知問題與限制

- 目前可下載版本僅支援 Apple Silicon（arm64），並要求 macOS 13 或更新版本。
- v1.0.0 尚未取得 Apple Developer ID 簽署與公證；Gatekeeper 首次開啟時可能會攔截。請參閱 Release 說明與 Apple 的[安全開啟指南](https://support.apple.com/en-us/102445)。
- 未授予「完全磁碟取用權限」時，受保護位置可能不會完整出現在掃描結果中。目前追蹤中的問題請見 [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues)。
## 🛡️ 安全漏洞回報與使用者回饋

- **安全漏洞：** 請透過 [GitHub Security Advisories 私密回報](https://github.com/letmetodo/aclean-mac/security/advisories/new)提交；請勿在公開 Issue 揭露漏洞細節。詳情請見 [SECURITY.md](SECURITY.md)。
- **錯誤回報與功能建議：** 請使用 [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new)，並提供 AClean 與 macOS 版本、相關模組、重現步驟、預期與實際結果，以及已移除個人路徑和隱私資料的記錄或截圖。
## 📜 授權條款

本專案採用 [Apache License 2.0](LICENSE)。

## 🧭 專案參考

功能與安全設計研究參考了多個獨立開源專案，包括 Clean-Me、Harbofly、MacSai、Mole、Pearcleaner、PureMac、ClearDisk、Tencent Lemon Cleaner、Lume、mac-cleaner-cli、mac-cleanup-py、mac-cleanup-sh、Purge、Xcode DevCleaner、MacSweep 與 Privacy Guides。此列表僅記錄研究參考，不代表認可或關聯。AClean 發布內容不會刻意包含上游原始碼或圖片；若未來貢獻加入第三方程式碼或資源，必須記錄來源與授權條款。
