<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean は、クリーニング、ディスク分析、アプリの削除、システム監視を行う macOS ネイティブアプリです。**

スキャン結果を確認してから操作でき、ディスク使用量を可視化し、アプリのアンインストール時に関連ファイルを確認できます。

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ スマートクリーニング · Space Lens · アプリ管理 · ライブモニター

- **スマートクリーニング** — 対応するアプリ、開発ツール、システムキャッシュをスキャンし、削除前に候補を確認します。
- **Space Lens** — 可視化されたツリーマップでディスク使用量を確認します。
- **アプリ管理** — インストール済みアプリと関連ファイルを削除前に確認します。
- **ライブモニター** — システムの動作を確認し、メニューバーウィジェットを設定します。
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.


## 🌟 AClean の特長

- **ネイティブアプリ自体がオープンソースです。** AClean の SwiftUI アプリは Apache-2.0 で公開され、確認・変更・再配布ができます。
- **複数の作業を一つのネイティブアプリに集約。** クリーンアップ候補の確認、ツリーマップによるディスク分析、アプリ削除前の関連ファイル確認、システムの健康状態の確認、メニューバーからの状態チェックを行えます。
- **確認してからクリーンアップ。** 実行前に、対応する候補とその場所を表示し、選択内容を確認できます。
- **10言語に対応。** アプリのインターフェースと README を10言語で用意しています。
- **ネットワーク利用を明示。** 任意のルール更新、天気、IP位置情報機能はネットワークを使用します。詳細は「クリーンアップとプライバシー」とソースコードをご覧ください。

## 📸 アプリ画面

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean ヘルスチェック module" width="500" /><br /><sub>ヘルスチェック</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean クリーン module" width="500" /><br /><sub>クリーン</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean 最適化 module" width="500" /><br /><sub>最適化</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean アプリケーション module" width="500" /><br /><sub>アプリケーション</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean 整理 module" width="500" /><br /><sub>整理</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean システム状態 module" width="500" /><br /><sub>システム状態</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 以降
- Swift 6.0 以降を含む Xcode Command Line Tools（または Xcode 16 以降）

## ソースからビルド

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean は Swift と macOS SDK で構築されています。ローカルビルドは Apple Silicon 向けです。 Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 プライバシー、スキャン範囲、削除

- **スキャン範囲:** モジュールに応じて、アプリ・ブラウザ・システムのキャッシュやログ、Xcode DerivedData/CoreSimulator などの開発データ、パッケージマネージャーのキャッシュ、インストール済みアプリと特定できた関連ファイルなど、ルールが対応するローカルパスを確認します。Space Lens はディスク使用量をローカルで読み取り専用表示します。一部の保護された場所にはフルディスクアクセスが必要です。許可されていない場合、結果は不完全になることがあります。
- **実行前の確認:** クリーンアップやアンインストールの候補名、パス、サイズを表示し、選択内容を確認してから実行します。
- **復元:** 通常のファイル削除とアプリの関連ファイルは macOS のゴミ箱へ移動し、ゴミ箱に残っている間は通常復元できます。ゴミ箱を空にする操作、Xcode シミュレーターデータの削除、Docker/OrbStack の prune、一部の APFS スナップショット回収は元に戻せない場合があります。実行前に操作種別と結果を確認してください。
- **ネットワーク通信:** ルール更新は既定で自動有効になり、HTTPS でルールのマニフェストとデータベースを取得します。サーバーには接続元 IP と通常のリクエスト情報が見えます。天気や IP 位置情報などの任意ネットワーク機能は既定で無効です。有効にすると位置情報プロバイダーには接続元 IP が見え、都市検索では入力した都市名と UI 言語を Open-Meteo に送信し、天気予報では緯度・経度を送信します。現在のネットワークリクエストにスキャンパス、ファイル名、クリーンアップ結果は含まれません。システム使用状況はローカル表示です。

## ⚠️ 既知の制限

- 現在のダウンロード版は Apple Silicon（arm64）専用で、macOS 13 以降が必要です。
- v1.0.0 は Apple Developer ID 署名と公証を受けていません。初回起動時に Gatekeeper がブロックする場合があります。Release Notes と Apple の[安全な起動方法](https://support.apple.com/en-us/102445)をご確認ください。
- フルディスクアクセスがないと、一部の保護された場所を完全にスキャンできません。追跡中の不具合は [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues) をご覧ください。
## 🛡️ 脆弱性の報告とフィードバック

- **セキュリティ脆弱性:** [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new) から非公開で報告してください。公開 Issue に脆弱性の詳細を書かないでください。詳しくは [SECURITY.md](SECURITY.md) をご覧ください。
- **不具合・機能要望:** [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new) を利用し、AClean と macOS のバージョン、対象モジュール、再現手順、期待する結果と実際の結果、個人パスなどを削除したログや画像を記載してください。
## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

Clean-Me、Harbofly、MacSai、Mole、Pearcleaner、PureMac、ClearDisk、Tencent Lemon Cleaner、Lume、mac-cleaner-cli、mac-cleanup-py、mac-cleanup-sh、Purge、Xcode DevCleaner、MacSweep、Privacy Guides を機能と安全設計の調査で参考にしました。独立したプロジェクトであり、推奨や提携を示すものではありません。AClean の実装、ルール、アイコンは別途管理しています。第三者コードや素材を追加する場合は、出典とライセンスを記録してください。
