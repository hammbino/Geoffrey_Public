#!/usr/bin/env python3
"""Classify security find-identity output without printing certificate names."""
import argparse
import json
import re
import sys


def check(listing, requested=None):
    identities = []
    for line in listing.splitlines():
        match = re.fullmatch(r'\s*\d+\)\s+([0-9A-Fa-f]{40})\s+"(Developer ID Application: [^"\r\n]+)"\s*', line)
        if match:
            identities.append((match[1].upper(), match[2]))
    report = {'developer_id_application_identities': len(identities),
              'requested_identity_configured': bool(requested)}
    if not identities:
        report.update(signing_status='blocked', reason='no_valid_developer_id_application_identity')
    elif requested and not any(requested == name or requested.upper() == digest for digest, name in identities):
        report.update(signing_status='blocked', reason='requested_identity_is_not_a_valid_developer_id_application_identity')
    else:
        report.update(signing_status='available', reason='certificate_check_only_not_release_acceptance')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--identity')
    args = parser.parse_args()
    result = check(sys.stdin.read(), args.identity)
    print(json.dumps(result, sort_keys=True))
    raise SystemExit(0 if result['signing_status'] == 'available' else 2)
