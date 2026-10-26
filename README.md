# AClean

**A native macOS utility for cleanup, disk analysis, app removal, and system monitoring.**

AClean brings everyday Mac maintenance tools into one SwiftUI app. Review scan results before taking action, explore disk usage visually, and inspect related files when uninstalling apps.

## Features

- **Smart Cleanup** — scan supported application, developer, and system cache locations and review candidates before cleanup.
- **Space Lens** — explore disk usage with a visual treemap.
- **App Manager** — inspect installed apps and related files before removal.
- **Live Monitor** — view system activity and configure menu bar widgets.
- **Multilingual UI** — includes Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools with Swift 6.0 or later (Xcode 16 or later)

## Build from source

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

The app is written in Swift and uses the macOS SDK. The local build is configured for Apple Silicon. See [Releases](https://github.com/letmetodo/aclean-mac/releases) for downloadable builds when available.

To run the repository's test suite:

```bash
./Tests/run_tests.sh
```

## Cleanup and privacy

AClean is designed to show scan candidates before cleanup. Review the selected items and their locations before confirming an operation. Read the source and the release notes for the behavior of a specific version; cleanup results depend on the installed apps and files on your Mac.

The app includes optional network-backed features such as rule updates, weather, and IP-based location. Review the source and the in-app settings to understand which features make network requests. Do not assume that every feature is offline-only.

## Contributing

Issues and pull requests are welcome. Please include your macOS version, AClean version, steps to reproduce, and relevant logs with personal information removed. Avoid posting security vulnerabilities publicly; use GitHub's private vulnerability reporting for this repository when it is enabled.

## License

Licensed under the [Apache License, Version 2.0](LICENSE).

## Project references

The following projects and tools were consulted during feature and safety-design research:

- [Clean-Me](https://github.com/Kevin-De-Koninck/Clean-Me), [Harbofly](https://github.com/carloshpdoc/Harbofly), [MacSai](https://github.com/iliyami/MacSai), [Mole](https://github.com/tw93/Mole)
- [Pearcleaner](https://github.com/alienator88/Pearcleaner), [PureMac](https://github.com/momenbasel/PureMac), [ClearDisk](https://github.com/bysiber/cleardisk), [Tencent Lemon Cleaner](https://github.com/Tencent/lemon-cleaner)
- [Lume](https://github.com/Tyooughtul/lume), [mac-cleaner-cli](https://github.com/guhcostan/mac-cleaner-cli), [mac-cleanup-py](https://github.com/mac-cleanup/mac-cleanup-py), [mac-cleanup-sh](https://github.com/mac-cleanup/mac-cleanup-sh)
- [Purge](https://github.com/jithin-sabu/purge-app), [Xcode DevCleaner](https://github.com/vashpan/xcode-dev-cleaner), [MacSweep](https://github.com/opencorex-org/macsweep), [Privacy Guides](https://github.com/sunknudsen/guides)

These are independent projects; this list records research references and does not imply endorsement or affiliation. No upstream source repository or image asset is intentionally bundled in the AClean release export. AClean's implementation, cleanup rules, and icon are maintained separately in this repository. If a future contribution adds third-party code or assets, its origin and license must be recorded with that contribution.
