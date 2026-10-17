#!/usr/bin/env python3
"""Inspect reachable ZIP metadata recursively; print aggregate counts only."""
import argparse
import io
import re
import subprocess
import zipfile

MAX_ARCHIVE = 200 * 1024 * 1024
MAX_EXPANDED = 256 * 1024 * 1024
MAX_ENTRIES = 30_000
MAX_DEPTH = 3


def risky_path(path):
    path = path.lower()
    base = path.rsplit('/', 1)[-1]
    media = bool(re.search(r'(screenshot|screen shot|recipient)', path)
                 and re.search(r'\.(png|jpg|jpeg|heic|pdf)$', path))
    archive = bool(re.search(r'private[-_ ]?beta|geoffrey.*\.app\.(zip|tar|gz)|\.dmg$', path))
    credential = bool(re.search(r'(^|/)(accounts\.json|google-oauth\.json|\.env(\..*)?|[^/]*\.(token|secret))$', path)
                      or re.match(r'client_secret.*\.json$', base))
    return media or archive or credential, credential


def inspect_archive(data, depth=0, budget=None):
    """Return risk, credential-path, incomplete flags without exposing names/data."""
    if budget is None:
        budget = {'bytes': MAX_EXPANDED, 'entries': MAX_ENTRIES}
    risk = credential = incomplete = False
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            entries = archive.infolist()
            budget['entries'] -= len(entries)
            if budget['entries'] < 0:
                return False, False, True
            for entry in entries:
                if entry.is_dir():
                    continue
                path_risk, path_credential = risky_path(entry.filename)
                risk |= path_risk
                credential |= path_credential
                if entry.filename.lower().endswith('.zip'):
                    if depth >= MAX_DEPTH or entry.file_size > min(MAX_ARCHIVE, budget['bytes']):
                        incomplete = True
                        continue
                    # Bound actual reads too; do not trust declared expanded sizes.
                    with archive.open(entry) as stream:
                        nested = stream.read(min(MAX_ARCHIVE, budget['bytes']) + 1)
                    budget['bytes'] -= len(nested)
                    if len(nested) > MAX_ARCHIVE or budget['bytes'] < 0:
                        incomplete = True
                        continue
                    child = inspect_archive(nested, depth + 1, budget)
                    risk |= child[0]
                    credential |= child[1]
                    incomplete |= child[2]
    except (zipfile.BadZipFile, ValueError, RuntimeError, NotImplementedError, OSError, EOFError):
        incomplete = True
    return risk, credential, incomplete


def git(repo, args, data=None):
    return subprocess.check_output(['git', '-C', repo, *args], input=data, stderr=subprocess.DEVNULL)


def audit(repo):
    objects = git(repo, ['rev-list', '--objects', '--all'])
    rows = git(repo, ['cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize) %(rest)'], objects)
    totals = {'history_zip_blobs': 0, 'history_zip_risky_blobs': 0,
              'history_zip_credential_path_blobs': 0, 'history_zip_uninspected_blobs': 0}
    for row in rows.decode('utf-8', errors='replace').splitlines():
        parts = row.split(' ', 3)
        if len(parts) != 4 or parts[1] != 'blob' or not parts[3].lower().endswith('.zip'):
            continue
        totals['history_zip_blobs'] += 1
        if int(parts[2]) > MAX_ARCHIVE:
            totals['history_zip_uninspected_blobs'] += 1
            continue
        flags = inspect_archive(git(repo, ['cat-file', 'blob', parts[0]]))
        totals['history_zip_risky_blobs'] += int(flags[0])
        totals['history_zip_credential_path_blobs'] += int(flags[1])
        totals['history_zip_uninspected_blobs'] += int(flags[2])
    return totals


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True)
    args = parser.parse_args()
    try:
        for key, value in audit(args.repo).items():
            print(f'{key}={value}')
    except (subprocess.CalledProcessError, ValueError):
        print('archive_audit=failed')
        raise SystemExit(1)
