#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:---local}"
if [[ "$MODE" == --development ]]; then MODE=--local; fi
[[ "$MODE" == --local || "$MODE" == --release ]] || { echo 'Use --local or --release'; exit 2; }
SIGN_IDENTITY="${ACLEAN_SIGN_IDENTITY:--}"
if [[ "$MODE" == --release ]]; then
  [[ "$SIGN_IDENTITY" != '-' && -n "${ACLEAN_NOTARY_PROFILE:-}" && -n "${CLEANMATE_VERSION:-}" && -n "${CLEANMATE_BUILD_NUMBER:-}" ]] || { echo 'Release requires signing identity, notary profile, version and build number'; exit 2; }
fi
STAGE="$(mktemp -d /private/tmp/cleanmate-build.XXXXXX)"
# Only remove the fresh directory allocated above, never the user's existing build/.
trap 'python3 "$ROOT/Tools/clean_build_stage.py" "$STAGE"' EXIT
APP="$STAGE/AClean.app"
BIN="$APP/Contents/MacOS/AClean"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Library/LaunchDaemons"
cp -R "$ROOT/Sources" "$STAGE/Sources"
SRCS=($(find "$STAGE/Sources" -name '*.swift' | sort))
if [[ "$MODE" == --release ]]; then
  SWIFT_OPT_FLAGS=(-O -whole-module-optimization)
  HELPER_SWIFT_OPT_FLAGS=(-O)
  HELPER_C_OPT_FLAGS=(-O2)
else
  # Local iteration favors compile time. Release builds retain whole-module optimization.
  SWIFT_OPT_FLAGS=(-Onone)
  HELPER_SWIFT_OPT_FLAGS=(-Onone)
  HELPER_C_OPT_FLAGS=(-O0)
fi
swiftc "${SWIFT_OPT_FLAGS[@]}" -parse-as-library -swift-version 6 -strict-concurrency=complete \
  -target arm64-apple-macosx13.0 -module-cache-path "$STAGE/ModuleCache" \
  -framework SwiftUI -framework AppKit -framework Foundation -framework UniformTypeIdentifiers \
  -framework IOKit -framework CoreAudio -framework CoreMediaIO -framework SystemConfiguration \
  -framework CoreWLAN -framework CoreLocation -framework Security -framework UserNotifications -lsqlite3 "${SRCS[@]}" -o "$BIN"
clang "${HELPER_C_OPT_FLAGS[@]}" -Dmain=aclean_smc_execute -target arm64-apple-macosx13.0 -c "$ROOT/Tools/smchelper.c" -o "$STAGE/smc.o"
swiftc "${HELPER_SWIFT_OPT_FLAGS[@]}" -parse-as-library -swift-version 6 -D CLEANMATE_HELPER -target arm64-apple-macosx13.0 -module-cache-path "$STAGE/ModuleCache" \
  -framework Foundation -framework Security -framework IOKit -framework CoreFoundation \
  "$ROOT/Tools/MaintenanceHelper.swift" "$ROOT/Sources/Core/PrivilegedMaintenanceProtocol.swift" \
  "$ROOT/Sources/Core/LockedValue.swift" "$ROOT/Sources/Core/AppConfig.swift" "$STAGE/smc.o" -o "$APP/Contents/MacOS/ACleanMaintenanceHelper"
cp "$ROOT/Resources/com.personal.aclean.maintenance-helper.plist" "$APP/Contents/Library/LaunchDaemons/"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp -R "$ROOT/Resources/"*.lproj "$APP/Contents/Resources/"
cp "$ROOT/Resources/cleanmate_authored_rules.sql" "$APP/Contents/Resources/"
cp "$ROOT/Resources/rule_safety.json" "$APP/Contents/Resources/"
python3 - "$APP/Contents/Info.plist" "$MODE" <<'PYCONFIG'
import os,sys,plistlib,urllib.parse
from pathlib import Path
path=Path(sys.argv[1]); info=plistlib.loads(path.read_bytes())
base=os.environ.get('CLEANMATE_RULES_BASE_URL',info.get('CleanMateRulesBaseURL',''))
if base:
    parsed=urllib.parse.urlparse(base)
    if parsed.scheme!='https' or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError('invalid_rule_update_url')
    info['CleanMateRulesBaseURL']=base
if sys.argv[2]=='--release' and not base:
    raise ValueError('release_rule_updates_not_configured')
path.write_bytes(plistlib.dumps(info))
PYCONFIG
swiftc -target arm64-apple-macosx13.0 -module-cache-path "$STAGE/ModuleCache" -framework AppKit "$ROOT/Tools/generate_icon.swift" -o "$STAGE/generate-icon"
"$STAGE/generate-icon" "$STAGE/AppIcon.iconset" "$ROOT/Resources/AppIcon.png"
python3 "$ROOT/Tools/package_icon.py" "$STAGE/AppIcon.iconset" "$APP/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${CLEANMATE_VERSION:-1.0}" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${CLEANMATE_BUILD_NUMBER:-1}" "$APP/Contents/Info.plist"
if [[ "$MODE" == --release ]]; then
  codesign --force --options runtime --identifier com.personal.aclean.maintenance-helper --sign "$SIGN_IDENTITY" "$APP/Contents/MacOS/ACleanMaintenanceHelper"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP"
  codesign --verify --deep --strict "$APP"
  ditto -c -k --keepParent "$APP" "$STAGE/AClean.zip"
  xcrun notarytool submit "$STAGE/AClean.zip" --keychain-profile "$ACLEAN_NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  spctl --assess --type execute "$APP"
else
  # Ad-hoc signing works locally and does not require a Developer ID account.
  codesign --force --identifier com.personal.aclean.maintenance-helper --sign - "$APP/Contents/MacOS/ACleanMaintenanceHelper"
  codesign --force --sign - "$APP"
fi
if [[ "$MODE" == --release ]]; then
  mkdir -p "$STAGE/image"
  cp -R "$APP" "$STAGE/image/"
  ln -s /Applications "$STAGE/image/Applications"
  hdiutil create -volname AClean -srcfolder "$STAGE/image" -format UDZO "$STAGE/AClean.dmg" >/dev/null
  codesign --sign "$SIGN_IDENTITY" "$STAGE/AClean.dmg"
  xcrun notarytool submit "$STAGE/AClean.dmg" --keychain-profile "$ACLEAN_NOTARY_PROFILE" --wait
  xcrun stapler staple "$STAGE/AClean.dmg"
fi
mkdir -p "$ROOT/build"
python3 - "$STAGE" "$ROOT/build" "$MODE" <<'PY'
from pathlib import Path
import shutil,sys,time
stage,output=map(Path,sys.argv[1:3])
mode=sys.argv[3]
names=['AClean.app'] + (['AClean.dmg'] if mode=='--release' else [])
for name in names:
    target=output/name
    if target.exists(): target.rename(output/(name+'.previous-'+str(time.time_ns())))
    shutil.move(str(stage/name),target)
PY
echo "Built $ROOT/build/AClean.app ($MODE, Apple Silicon)."
