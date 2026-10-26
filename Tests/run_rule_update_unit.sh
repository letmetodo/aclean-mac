#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CASE="${1:-manifest}"
STAGE="$(mktemp -d /private/tmp/cleanmate-build.rule-unit.XXXXXX)"
trap 'python3 "$ROOT/Tools/clean_build_stage.py" "$STAGE"' EXIT
swiftc -swift-version 6 -strict-concurrency=complete -parse-as-library \
  -module-cache-path "$STAGE/ModuleCache" \
  "$ROOT/Sources/Rules/RulePackageProtocol.swift" "$ROOT/Sources/Rules/RuleDatabase.swift" \
  "$ROOT/Sources/Rules/RuleHTTPClient.swift" "$ROOT/Sources/Rules/RulePackageStore.swift" "$ROOT/Sources/Rules/RuleTaskGate.swift" "$ROOT/Tests/RuleUpdateUnitTests.swift" \
  -lsqlite3 \
  -o "$STAGE/RuleUnit"
if [[ "$CASE" == "all" ]]; then
  for unitCase in manifest duplicates invalid-manifest rollback single-store install-recovery task-gate download-limits database-text; do
    echo "==> Rule unit: $unitCase"
    "$STAGE/RuleUnit" "$unitCase"
  done
else
  "$STAGE/RuleUnit" "$@"
fi
