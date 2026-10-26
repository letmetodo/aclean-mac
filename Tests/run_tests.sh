#!/bin/zsh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 复制到临时快照目录编译，防止外部文件索引器/监听器在编译期间触碰源文件时间戳导致 swiftc 中断
STAGE_DIR="${ACLEAN_TEST_STAGE_DIR:-$(mktemp -d /private/tmp/cleanmate-build.tests.XXXXXX)}"
if [[ -z "$ACLEAN_TEST_STAGE_DIR" ]]; then
  trap 'python3 "$ROOT/Tools/clean_build_stage.py" "$STAGE_DIR"' EXIT
fi
TEST_BIN="$STAGE_DIR/AllTests"
mkdir -p "$STAGE_DIR/Sources" "$STAGE_DIR/Tests" "$STAGE_DIR/Resources"
cp -R "$ROOT/Sources/" "$STAGE_DIR/Sources/"
cp -R "$ROOT/Tests/" "$STAGE_DIR/Tests/"
python3 "$ROOT/Tools/build_authored_rules.py" --sql "$ROOT/Resources/cleanmate_authored_rules.sql" --out "$STAGE_DIR/Resources/cleanmate_rules.db"
cp "$ROOT/Resources/cleanmate_authored_rules.sql" "$ROOT/Resources/rule_safety.json" "$STAGE_DIR/Resources/"
python3 - "$STAGE_DIR/TestHome" <<'PYFIXTURE'
from pathlib import Path
import sys
home = Path(sys.argv[1])
for relative in ['Library/Caches/com.cleanmate.fixture/cache.bin',
                 'Library/Application Support/Google/Chrome/Default/Cache/Cache_Data/data.bin',
                 'Library/HTTPStorages/com.cleanmate.fixture/session.bin']:
    file = home/relative
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_bytes(b'x' * 262144)
PYFIXTURE

# 收集除 CleanMateApp.swift/App.swift 之外的所有 Sources 文件，加上各阶段测试文件
SRCS=($(find "$STAGE_DIR/Sources" -name '*.swift' ! -name 'App.swift' ! -name 'CleanMateApp.swift' | sort))
SRCS+=($(find "$STAGE_DIR/Tests" -name 'P*.swift' | sort))

echo "==> 编译全量 P0 ~ P9 自动化单元测试 (${#SRCS[@]} 个 Swift 源文件)..."
swiftc -D DEBUG -Onone -whole-module-optimization -module-cache-path "$STAGE_DIR/ModuleCache" -Xfrontend -assert-config -Xfrontend Debug -parse-as-library -swift-version 5 \
  -target arm64-apple-macosx13.0 \
  -framework SwiftUI -framework AppKit -framework Foundation -framework UniformTypeIdentifiers \
  -framework IOKit -framework CoreWLAN -framework CoreLocation -framework CoreAudio -framework CoreMediaIO -framework SystemConfiguration -framework UserNotifications \
  -lsqlite3 \
  "${SRCS[@]}" \
  -o "$TEST_BIN"

echo "==> 执行全量自动化测试套件..."
ACLEAN_RULES_DB="$STAGE_DIR/Resources/cleanmate_rules.db" ACLEAN_TEST_HOME="$STAGE_DIR/TestHome" "$TEST_BIN" "$@"
