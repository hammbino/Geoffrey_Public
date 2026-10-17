#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

printf '== Shell syntax\n'
bash -n bin/geoffrey scripts/*.sh

printf '\n== Connector syntax and behavioral tests\n'
for file in geoffrey-mcp/src/*.js geoffrey-mcp/src/providers/*.js geoffrey-mcp/bin/*.js; do
  node --check "$file"
done
npm test --prefix geoffrey-mcp

printf '\n== Historical archive audit tests\n'
PYTHONDONTWRITEBYTECODE=1 python3 ./scripts/test-history-archives.py

printf '\n== Dustin release gate (report only)\n'
node ./scripts/check-dustin-release-gate.mjs --report-only

printf '\n== Release evidence isolation\n'
./scripts/check-release-evidence-isolation.sh

printf '\n== Claude packages\n'
./scripts/check-claude-setup.sh

printf '\n== Mac application build and checks\n'
./scripts/build-mac-app.sh
./scripts/check-mac-app.sh
codesign --verify --deep --strict --verbose=2 build/Geoffrey.app

printf '\n== Patch hygiene\n'
git diff --check

printf '\nGeoffrey local verification passed. This does not by itself establish Dustin release readiness.\n'
