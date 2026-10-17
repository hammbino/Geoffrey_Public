#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_ONLY=false
if [ "${1:-}" = "--report-only" ]; then REPORT_ONLY=true; fi

AUDIT_TMP="$(mktemp -d)"
trap 'rm -rf "$AUDIT_TMP"' EXIT

git -C "$ROOT" rev-list --objects --all \
  | git -C "$ROOT" cat-file --batch-check='%(objectname) %(objecttype) %(objectsize) %(rest)' \
  > "$AUDIT_TMP/objects.txt"

summary="$(awk '
  BEGIN { media=0; media_bytes=0; archives=0; archive_bytes=0; credentials=0; credential_bytes=0 }
  $2 == "blob" {
    path=tolower($4)
    for (i=5; i<=NF; i++) path=path " " tolower($i)
    if (path ~ /(screenshot|screen shot|recipient)/ && path ~ /\.(png|jpg|jpeg|heic|pdf)$/) {
      media++; media_bytes += $3
    }
    if (path ~ /private[-_ ]?beta|geoffrey.*\.app\.(zip|tar|gz)|\.dmg$/) {
      archives++; archive_bytes += $3
    }
    if (path ~ /(^|\/)(accounts\.json|google-oauth\.json|client_secret[^\/]*\.json|\.env(\..*)?|[^\/]*\.(token|secret))$/) {
      credentials++; credential_bytes += $3
    }
  }
  END {
    printf "recipient_media_objects=%d\n", media
    printf "recipient_media_bytes=%d\n", media_bytes
    printf "private_app_archive_objects=%d\n", archives
    printf "private_app_archive_bytes=%d\n", archive_bytes
    printf "credential_path_objects=%d\n", credentials
    printf "credential_path_bytes=%d\n", credential_bytes
  }
' "$AUDIT_TMP/objects.txt")"

archive_summary="$(python3 "$ROOT/scripts/audit-history-archives.py" --repo "$ROOT")"
archive_risks="$(printf '%s\n' "$archive_summary" | awk -F= '$1 == "history_zip_risky_blobs" { print $2 }')"
archive_uninspected="$(printf '%s\n' "$archive_summary" | awk -F= '$1 == "history_zip_uninspected_blobs" { print $2 }')"

printf '%s\n' "$summary"
printf '%s\n' "$archive_summary"

media="$(printf '%s\n' "$summary" | awk -F= '$1 == "recipient_media_objects" { print $2 }')"
archives="$(printf '%s\n' "$summary" | awk -F= '$1 == "private_app_archive_objects" { print $2 }')"
credentials="$(printf '%s\n' "$summary" | awk -F= '$1 == "credential_path_objects" { print $2 }')"

if [ "${archive_uninspected:-1}" -gt 0 ]; then
  printf 'status=audit_incomplete\n'
  if [ "$REPORT_ONLY" = true ]; then exit 0; fi
  exit 2
fi

if [ "${archive_risks:-0}" -gt 0 ] || [ "${media:-0}" -gt 0 ] || [ "${archives:-0}" -gt 0 ] || [ "${credentials:-0}" -gt 0 ]; then
  printf 'status=rewrite_required\n'
  if [ "$REPORT_ONLY" = true ]; then exit 0; fi
  exit 2
fi

printf 'status=clean\n'
