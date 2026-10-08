#!/usr/bin/env bash
#
# Rebuild every distributable ZIP in dist/ from the source trees.
#
# Sources of truth:
#   .claude/skills/<skill>/   Claude Code project skills; also the fallback ZIP source
#   plugins/geoffrey/           Claude Desktop plugin, including which skills it ships
#   core/skills/, packs/      Canonical organized copies
#
# Skills are discovered from .claude/skills/ rather than hardcoded, so adding a
# skill does not silently skip it here.
#
# The build aborts if the source copies have drifted from each other. A rebuild
# must never quietly pick one version of a skill over another; fix the drift
# first, then build.
#
# Build order matters: the bundles embed the plugin ZIP and the fallback ZIPs,
# so those are built before the bundles are staged.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SKILLS_DIR=".claude/skills"
PLUGIN_SRC="plugins/geoffrey"
PLUGIN_ZIP="dist/Geoffrey-Claude-Plugin.zip"
FALLBACK_DIR="dist/claude-skills"
BUNDLE_MAURICIO="dist/Geoffrey-for-Claude-Mauricio.zip"
BUNDLE_FULL="dist/Geoffrey-for-Claude-Full-with-Reference.zip"

ok()   { printf 'OK    %s\n' "$1"; }
step() { printf '\n== %s\n' "$1"; }
die()  { printf 'ABORT %s\n' "$1" >&2; exit 1; }

command -v zip   >/dev/null 2>&1 || die "zip is not installed."
command -v rsync >/dev/null 2>&1 || die "rsync is not installed."

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# --- Discover skills --------------------------------------------------------

step "Discovering skills"

SKILLS=""
for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || die "No skills found under $SKILLS_DIR."
  skill="$(basename "$dir")"
  [ -f "$dir/SKILL.md" ] || die "Skill has no SKILL.md: $skill"
  grep -q "^name: $skill$" "$dir/SKILL.md" \
    || die "Skill frontmatter name does not match its folder: $skill"
  SKILLS="$SKILLS $skill"
done
[ -n "$SKILLS" ] || die "No skills found under $SKILLS_DIR."
ok "Skills:$SKILLS"

# --- Verify source copies agree before building anything --------------------

step "Verifying source copies are in sync"

# A skill's canonical home is core/skills/<skill> for Core skills, or
# packs/<skill>/skills/<skill> for pack skills. Compare whole directories so
# reference files travel with the skill, not just SKILL.md.
canonical_dir() {
  skill="$1"
  if [ -d "core/skills/$skill" ]; then
    printf 'core/skills/%s' "$skill"
  elif [ -d "packs/$skill/skills/$skill" ]; then
    printf 'packs/%s/skills/%s' "$skill" "$skill"
  else
    printf ''
  fi
}

for skill in $SKILLS; do
  src="$SKILLS_DIR/$skill"

  canon="$(canonical_dir "$skill")"
  if [ -n "$canon" ]; then
    diff -r "$src" "$canon" >/dev/null 2>&1 \
      || die "Drift: $src differs from $canon. Sync them, then rebuild."
  else
    die "Skill has no canonical copy under core/skills/ or packs/: $skill"
  fi

  plugin_copy="$PLUGIN_SRC/skills/$skill"
  if [ -d "$plugin_copy" ]; then
    diff -r "$src" "$plugin_copy" >/dev/null 2>&1 \
      || die "Drift: $src differs from $plugin_copy. Sync them, then rebuild."
  fi
done
ok "All skill copies agree"

[ -f "$PLUGIN_SRC/.claude-plugin/plugin.json" ] \
  || die "Missing plugin manifest: $PLUGIN_SRC/.claude-plugin/plugin.json"
ok "Plugin manifest present"

# --- 1. Fallback skill ZIPs -------------------------------------------------

step "Building fallback skill ZIPs"

mkdir -p "$FALLBACK_DIR"
for skill in $SKILLS; do
  target="$FALLBACK_DIR/$skill.zip"
  rm -f "$target"
  # Zip from inside .claude/skills so the archive has exactly one top-level
  # folder named after the skill, which is what Claude Desktop expects.
  ( cd "$SKILLS_DIR" && zip -rXq "$ROOT/$target" "$skill" -x '*.DS_Store' )
  ok "$target"
done

# Remove fallback ZIPs for skills that no longer exist.
for existing in "$FALLBACK_DIR"/*.zip; do
  [ -e "$existing" ] || continue
  name="$(basename "$existing" .zip)"
  case " $SKILLS " in
    *" $name "*) ;;
    *) rm -f "$existing"; ok "removed stale $existing" ;;
  esac
done

# --- 2. Plugin ZIP ----------------------------------------------------------

step "Building plugin ZIP"

rm -f "$PLUGIN_ZIP"
# Zip from inside plugins/ so the archive root is geoffrey/, matching the layout
# Claude Desktop expects on upload.
( cd "$(dirname "$PLUGIN_SRC")" && zip -rXq "$ROOT/$PLUGIN_ZIP" "$(basename "$PLUGIN_SRC")" -x '*.DS_Store' )
ok "$PLUGIN_ZIP"

# --- 3. Bundles -------------------------------------------------------------

step "Building repo bundles"

# Stage the repo as Geoffrey/ so both bundles share one root folder. The bundles
# are excluded from their own staging so they never embed each other.
rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude '.gitignore' \
  --exclude 'build/' \
  --exclude "$(basename "$BUNDLE_MAURICIO")" \
  --exclude "$(basename "$BUNDLE_FULL")" \
  ./ "$STAGE/Geoffrey/"

( cd "$STAGE" && zip -rXq full.zip Geoffrey )
mv "$STAGE/full.zip" "$BUNDLE_FULL"
ok "$BUNDLE_FULL (includes reference/)"

# reference/ is research material and is not redistributed in the handoff copy.
( cd "$STAGE" && zip -rXq mauricio.zip Geoffrey -x 'Geoffrey/reference/*' )
mv "$STAGE/mauricio.zip" "$BUNDLE_MAURICIO"
ok "$BUNDLE_MAURICIO (excludes reference/)"

# --- Done -------------------------------------------------------------------

printf '\nBuild complete. Verify with:\n  ./scripts/check-claude-setup.sh\n'
