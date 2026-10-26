<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean은 정리, 디스크 분석, 앱 제거, 시스템 모니터링을 위한 네이티브 macOS 앱입니다.**

정리 전에 스캔 결과를 검토하고, 디스크 사용량을 시각적으로 살펴보며, 앱을 제거할 때 관련 파일을 확인할 수 있습니다.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ 스마트 정리 · Space Lens · 앱 관리자 · 실시간 모니터

- **스마트 정리** — 지원되는 앱, 개발자 도구 및 시스템 캐시 위치를 스캔하고 정리 전에 항목을 검토합니다.
- **Space Lens** — 시각적 트리맵으로 디스크 사용량을 살펴봅니다.
- **앱 관리자** — 설치된 앱과 관련 파일을 제거 전에 확인합니다.
- **실시간 모니터** — 시스템 활동을 보고 메뉴 막대 위젯을 설정합니다.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.


## 🌟 AClean의 차별점

- **네이티브 앱 자체가 오픈 소스입니다.** AClean의 SwiftUI 앱은 Apache-2.0으로 공개되어 검토, 수정, 재배포할 수 있습니다.
- **하나의 네이티브 앱에서 여러 작업을 처리합니다.** 정리 후보를 미리 보고, 트리맵으로 디스크를 분석하고, 앱 제거 전에 관련 파일을 확인하며, 시스템 상태를 살펴보고 메뉴 막대에서 빠르게 확인할 수 있습니다.
- **검토 후 정리합니다.** 정리를 확정하기 전에 지원되는 후보 항목과 경로를 표시해 선택 내용을 확인할 수 있습니다.
- **10개 언어를 지원합니다.** 앱 인터페이스와 README를 10개 언어로 제공합니다.
- **네트워크 사용을 공개합니다.** 선택형 규칙 업데이트, 날씨, IP 기반 위치 기능은 네트워크를 사용합니다. 자세한 내용은 ‘정리 및 개인정보 보호’와 소스 코드에서 확인할 수 있습니다.

## 📸 실제 앱 화면

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean 건강 확인 module" width="500" /><br /><sub>건강 확인</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean 정리 module" width="500" /><br /><sub>정리</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean 최적화 module" width="500" /><br /><sub>최적화</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean 앱 관리 module" width="500" /><br /><sub>앱 관리</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean 파일 정돈 module" width="500" /><br /><sub>파일 정돈</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean 시스템 상태 module" width="500" /><br /><sub>시스템 상태</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 이상
- Swift 6.0 이상이 포함된 Xcode Command Line Tools (또는 Xcode 16 이상)

## 소스에서 빌드

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean은 Swift와 macOS SDK로 작성되었습니다. 로컬 빌드는 Apple Silicon을 대상으로 합니다. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 개인정보 보호, 검사 범위 및 삭제

- **검사 범위:** 모듈에 따라 앱·브라우저·시스템 캐시와 로그, Xcode DerivedData/CoreSimulator 같은 개발 데이터, 패키지 관리자 캐시, 설치된 앱과 식별 가능한 관련 파일 등 규칙이 지원하는 로컬 경로를 검사합니다. Space Lens는 디스크 사용량을 로컬에서 읽기 전용으로 표시합니다. 일부 보호된 위치는 전체 디스크 접근 권한이 필요하며, 권한이 없으면 결과가 불완전할 수 있습니다.
- **실행 전 검토:** 정리 및 앱 제거 후보의 이름, 경로, 크기를 표시하므로 선택 내용을 확인한 뒤 진행할 수 있습니다.
- **복구 가능성:** 일반 파일 정리와 앱 관련 파일은 macOS 휴지통으로 이동하며, 휴지통에 남아 있는 동안에는 대체로 복원할 수 있습니다. 휴지통 비우기, Xcode 시뮬레이터 데이터 삭제, Docker/OrbStack prune, 일부 APFS 스냅샷 회수는 되돌릴 수 없을 수 있습니다. 실행 전에 작업 유형과 결과를 확인하세요.
- **네트워크 전송:** 규칙 업데이트는 기본적으로 자동 활성화되어 HTTPS로 규칙 매니페스트와 데이터베이스를 내려받습니다. 서버에는 요청 IP와 일반 요청 메타데이터가 보입니다. 날씨 및 IP 위치 기능은 기본적으로 꺼져 있습니다. 켜면 위치 제공자가 요청 IP를 볼 수 있고, 도시 검색은 입력한 도시명과 인터페이스 언어를 Open-Meteo로 보내며, 일기예보 요청은 위도와 경도를 보냅니다. 현재 네트워크 요청에는 검사 경로, 파일명 또는 정리 결과가 포함되지 않습니다. 시스템 사용량은 로컬에 표시됩니다.

## ⚠️ 알려진 제한 사항

- 현재 다운로드 빌드는 Apple Silicon(arm64) 전용이며 macOS 13 이상이 필요합니다.
- v1.0.0은 Apple Developer ID 서명 및 공증이 없습니다. 첫 실행에서 Gatekeeper가 차단할 수 있습니다. Release 노트와 Apple의 [안전한 앱 열기 안내](https://support.apple.com/en-us/102445)를 확인하세요.
- 전체 디스크 접근 권한이 없으면 일부 보호된 위치를 완전히 검사할 수 없습니다. 현재 추적 중인 버그는 [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues)에서 확인하세요.
## 🛡️ 보안 취약점 신고 및 피드백

- **보안 취약점:** [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new)를 통해 비공개로 신고해 주세요. 공개 Issue에 취약점 세부 정보를 올리지 마세요. 자세한 내용은 [SECURITY.md](SECURITY.md)를 참고하세요.
- **버그 및 기능 제안:** [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new)에 AClean/macOS 버전, 관련 모듈, 재현 단계, 예상 결과와 실제 결과, 개인 경로 등 민감정보를 제거한 로그나 스크린샷을 첨부해 주세요.
## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

기능 및 안전 설계 조사에서 Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep, Privacy Guides를 참고했습니다. 이들은 별개의 프로젝트이며 승인이나 제휴를 의미하지 않습니다. AClean 구현, 정리 규칙 및 아이콘은 별도로 관리됩니다. 향후 기여에 타사 코드나 자료가 추가되면 출처와 라이선스를 기록해야 합니다.
