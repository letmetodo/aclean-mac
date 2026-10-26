# AClean

**AClean은 정리, 디스크 분석, 앱 제거, 시스템 모니터링을 위한 네이티브 macOS 앱입니다.**

정리 전에 스캔 결과를 검토하고, 디스크 사용량을 시각적으로 살펴보며, 앱을 제거할 때 관련 파일을 확인할 수 있습니다.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## 스마트 정리 · Space Lens · 앱 관리자 · 실시간 모니터

- **스마트 정리** — 지원되는 앱, 개발자 도구 및 시스템 캐시 위치를 스캔하고 정리 전에 항목을 검토합니다.
- **Space Lens** — 시각적 트리맵으로 디스크 사용량을 살펴봅니다.
- **앱 관리자** — 설치된 앱과 관련 파일을 제거 전에 확인합니다.
- **실시간 모니터** — 시스템 활동을 보고 메뉴 막대 위젯을 설정합니다.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.

## Requirements

- macOS 13 이상
- Swift 6.0 이상이 포함된 Xcode Command Line Tools (또는 Xcode 16 이상)

## 소스에서 빌드

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean은 Swift와 macOS SDK로 작성되었습니다. 로컬 빌드는 Apple Silicon을 대상으로 합니다. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## Cleanup and privacy

AClean은 정리 전에 스캔 항목을 표시합니다. 작업을 확인하기 전에 선택 항목과 위치를 검토하세요. 동작은 버전에 따라 다를 수 있으므로 소스와 릴리스 노트를 확인하세요. 규칙 업데이트, 날씨, IP 기반 위치와 같은 선택적 네트워크 기능이 포함되어 있습니다. 모든 기능이 오프라인으로 동작한다고 가정하지 마세요.

## Contributing

Issue와 Pull Request를 환영합니다. macOS 및 AClean 버전, 재현 단계, 개인 정보가 제거된 로그를 포함해 주세요.

## License

Licensed under the [Apache License 2.0](LICENSE).

## Project references

기능 및 안전 설계 조사에서 Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep, Privacy Guides를 참고했습니다. 이들은 별개의 프로젝트이며 승인이나 제휴를 의미하지 않습니다. AClean 구현, 정리 규칙 및 아이콘은 별도로 관리됩니다. 향후 기여에 타사 코드나 자료가 추가되면 출처와 라이선스를 기록해야 합니다.
