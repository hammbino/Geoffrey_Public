#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

say() {
  printf '%s\n' "$1"
}

ok() {
  printf 'OK  %s\n' "$1"
}

bad() {
  printf 'NO  %s\n' "$1"
  FAIL=1
}

note() {
  printf 'NOTE  %s\n' "$1"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Compare a ZIP's contents against a source directory. Existence and shape
# checks pass happily on a stale ZIP, so freshness has to be checked by
# extracting and diffing the real contents.
#
# zip_matches <zip-file> <path-inside-zip> <source-dir>
zip_matches() {
  zip_file="$1"
  inner="$2"
  src_dir="$3"
  work="$TMP/cmp-$$-$RANDOM"

  rm -rf "$work"
  mkdir -p "$work"
  unzip -q "$zip_file" -d "$work" 2>/dev/null || return 1
  [ -e "$work/$inner" ] || return 1
  diff -r "$work/$inner" "$src_dir" >/dev/null 2>&1
}

say "Geoffrey Claude package check"
say "Root: $ROOT"
say ""

if command -v claude >/dev/null 2>&1; then
  ok "Claude Code found: $(claude --version 2>/dev/null | head -n 1)"
else
  note "Claude Code not found. Claude Desktop plugin upload can still work; install Claude Code for the local project path."
fi

for path in \
  "$ROOT/CLAUDE.md" \
  "$ROOT/START_HERE.md" \
  "$ROOT/HANDOFF.md" \
  "$ROOT/.claude/skills" \
  "$ROOT/plugins/geoffrey/.claude-plugin/plugin.json" \
  "$ROOT/plugins/geoffrey/skills" \
  "$ROOT/core/skills" \
  "$ROOT/packs" \
  "$ROOT/docs/handoff-packet-template.md" \
  "$ROOT/docs/mauricio-onboarding-packet.md" \
  "$ROOT/docs" \
  "$ROOT/dist/Geoffrey-Claude-Plugin.zip" \
  "$ROOT/dist/claude-skills"; do
  if [ -e "$path" ]; then
    ok "Exists: ${path#$ROOT/}"
  else
    bad "Missing: ${path#$ROOT/}"
  fi
done

say ""
say "Checking Claude plugin, fallback skill ZIPs, and Claude Code project skills..."

if [ -f "$ROOT/dist/Geoffrey-Claude-Plugin.zip" ]; then
  if unzip -Z1 "$ROOT/dist/Geoffrey-Claude-Plugin.zip" 2>/dev/null | grep -q "^geoffrey/.claude-plugin/plugin.json$"; then
    ok "Plugin ZIP has manifest: dist/Geoffrey-Claude-Plugin.zip"
  else
    bad "Plugin ZIP missing geoffrey/.claude-plugin/plugin.json"
  fi
fi

# Discover skills instead of hardcoding them, so a newly added skill cannot
# silently skip every check below.
SKILLS=""
for skill_dir in "$ROOT/.claude/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  SKILLS="$SKILLS $(basename "$skill_dir")"
done

if [ -z "$SKILLS" ]; then
  bad "No skills found under .claude/skills/"
else
  ok "Discovered skills:$SKILLS"
fi

for skill in $SKILLS; do
  skill_file="$ROOT/.claude/skills/$skill/SKILL.md"
  plugin_skill_file="$ROOT/plugins/geoffrey/skills/$skill/SKILL.md"
  zip_file="$ROOT/dist/claude-skills/$skill.zip"

  if [ -f "$skill_file" ]; then
    ok "Claude Code skill file: .claude/skills/$skill/SKILL.md"
  else
    bad "Missing Claude Code skill file: .claude/skills/$skill/SKILL.md"
    continue
  fi

  if [ -f "$plugin_skill_file" ]; then
    ok "Plugin skill file: plugins/geoffrey/skills/$skill/SKILL.md"
  else
    bad "Missing plugin skill file: plugins/geoffrey/skills/$skill/SKILL.md"
  fi

  if grep -q "^name: $skill$" "$skill_file"; then
    ok "Skill name matches folder: $skill"
  else
    bad "Skill name does not match folder: $skill"
  fi

  if grep -q "^description:" "$skill_file"; then
    ok "Skill has description: $skill"
  else
    bad "Skill missing description: $skill"
  fi

  if grep -q "TODO\\|\\[TODO" "$skill_file"; then
    bad "Skill contains TODO placeholder: $skill"
  fi

  if [ -f "$ROOT/dist/Geoffrey-Claude-Plugin.zip" ]; then
    if unzip -Z1 "$ROOT/dist/Geoffrey-Claude-Plugin.zip" 2>/dev/null | grep -q "^geoffrey/skills/$skill/SKILL.md$"; then
      ok "Plugin ZIP includes skill: $skill"
    else
      bad "Plugin ZIP missing skill: $skill"
    fi
  fi

  if [ -f "$zip_file" ]; then
    ok "Fallback skill ZIP exists: dist/claude-skills/$skill.zip"
    top_level_count="$(unzip -Z1 "$zip_file" 2>/dev/null | awk -F/ 'NF {print $1}' | sort -u | wc -l | tr -d ' ')"
    if [ "$top_level_count" = "1" ] && unzip -Z1 "$zip_file" 2>/dev/null | grep -q "^$skill/SKILL.md$"; then
      ok "Fallback ZIP shape is valid: $skill.zip"
    else
      bad "Fallback ZIP should contain one top-level folder with SKILL.md: $skill.zip"
    fi

    if zip_matches "$zip_file" "$skill" "$ROOT/.claude/skills/$skill"; then
      ok "Fallback ZIP is current: $skill.zip"
    else
      bad "Fallback ZIP is STALE, contents differ from .claude/skills/$skill: $skill.zip"
    fi
  else
    bad "Missing fallback skill ZIP: dist/claude-skills/$skill.zip"
  fi
done

say ""
say "Checking that distributable ZIPs match current source..."

if [ -f "$ROOT/dist/Geoffrey-Claude-Plugin.zip" ]; then
  if zip_matches "$ROOT/dist/Geoffrey-Claude-Plugin.zip" "geoffrey/skills" "$ROOT/plugins/geoffrey/skills"; then
    ok "Plugin ZIP is current: dist/Geoffrey-Claude-Plugin.zip"
  else
    bad "Plugin ZIP is STALE, skills differ from plugins/geoffrey/skills"
  fi
fi

for bundle in \
  "$ROOT/dist/Geoffrey-for-Claude-Mauricio.zip" \
  "$ROOT/dist/Geoffrey-for-Claude-Full-with-Reference.zip"; do
  bundle_name="$(basename "$bundle")"

  if [ ! -f "$bundle" ]; then
    bad "Missing bundle: dist/$bundle_name"
    continue
  fi

  # These bundles are whole-repo snapshots, so checking only the skills would
  # miss stale docs, CLAUDE.md, or scripts. Compare the whole tree instead.
  # dist/ is excluded because nested ZIPs differ byte-wise on every rebuild even
  # when their contents are identical; they are verified separately below.
  case "$bundle_name" in
    *Mauricio*) bundle_excludes="-x .git -x dist -x build -x .gitignore -x .DS_Store -x reference" ;;
    *)          bundle_excludes="-x .git -x dist -x build -x .gitignore -x .DS_Store" ;;
  esac

  bundle_work="$TMP/bundle-$bundle_name"
  rm -rf "$bundle_work"
  mkdir -p "$bundle_work"
  if unzip -q "$bundle" -d "$bundle_work" 2>/dev/null; then
    if diff -r $bundle_excludes "$bundle_work/Geoffrey" "$ROOT" >/dev/null 2>&1; then
      ok "Bundle contents are current: $bundle_name"
    else
      bad "Bundle is STALE, contents differ from the working tree: $bundle_name"
    fi
  fi

  # A bundle can carry current files while embedding an outdated plugin ZIP,
  # which is the copy a Desktop user actually installs.
  if [ -d "$bundle_work/Geoffrey" ]; then
    nested_plugin="$bundle_work/Geoffrey/dist/Geoffrey-Claude-Plugin.zip"
    if [ -f "$nested_plugin" ]; then
      if zip_matches "$nested_plugin" "geoffrey/skills" "$ROOT/plugins/geoffrey/skills"; then
        ok "Bundle's embedded plugin ZIP is current: $bundle_name"
      else
        bad "Bundle embeds a STALE plugin ZIP: $bundle_name"
      fi
    else
      bad "Bundle is missing dist/Geoffrey-Claude-Plugin.zip: $bundle_name"
    fi
  else
    bad "Bundle could not be extracted: $bundle_name"
  fi
done

# The handoff bundle must not carry research material. This is a source
# boundary, not a size optimization.
if [ -f "$ROOT/dist/Geoffrey-for-Claude-Mauricio.zip" ]; then
  if unzip -Z1 "$ROOT/dist/Geoffrey-for-Claude-Mauricio.zip" 2>/dev/null | grep -q "^Geoffrey/reference/"; then
    bad "Handoff bundle contains reference/ material: Geoffrey-for-Claude-Mauricio.zip"
  else
    ok "Handoff bundle excludes reference/"
  fi
fi

say ""
if [ "$FAIL" -eq 0 ]; then
  say "Geoffrey is ready for one-file Claude Desktop plugin upload and Claude Code project use."
  say ""
  say "Claude Desktop:"
  say "  Upload dist/Geoffrey-Claude-Plugin.zip from Customize > Plugins, then start a chat with:"
  say "  Use the Geoffrey plugin and onboard me. I am busy and want to reduce load, mental fatigue, and process."
  say ""
  say "Claude Code:"
  say "  cd \"$ROOT\""
  say "  claude"
  say "  /recipient-onboarding I am handing Geoffrey to a busy business owner. Start with no more than three questions, then help with one useful task immediately."
else
  say "Geoffrey package check failed. Fix the NO lines above and rerun this script."
  say ""
  say "If the failures are STALE ZIPs, rebuild them from source:"
  say "  ./scripts/build-dist.sh"
fi

exit "$FAIL"
