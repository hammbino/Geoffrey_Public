#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import subprocess
import unittest

spec = importlib.util.spec_from_file_location('signing_identity', Path(__file__).with_name('check-mac-signing-identity.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
DIGEST = 'A' * 40
NAME = 'Developer ID Application: Synthetic Fixture (TEAM123456)'
LISTING = f'  1) {DIGEST} "{NAME}"\n     1 valid identities found\n'


class SigningIdentityTests(unittest.TestCase):
    def test_no_or_wrong_certificate_type_blocks(self):
        for listing in ['', '0 valid identities found', LISTING.replace('Developer ID Application:', 'Apple Development:'), LISTING.replace('Developer ID Application:', 'Developer ID Installer:')]:
            self.assertEqual(module.check(listing)['signing_status'], 'blocked')

    def test_exact_name_or_fingerprint_is_supported(self):
        for requested in [None, NAME, DIGEST, DIGEST.lower()]:
            self.assertEqual(module.check(LISTING, requested)['signing_status'], 'available')

    def test_ad_hoc_missing_and_partial_names_block(self):
        for requested in ['-', 'Synthetic Fixture', NAME + ' wrong', 'B' * 40]:
            self.assertEqual(module.check(LISTING, requested)['signing_status'], 'blocked')

    def test_invalid_and_revoked_rows_are_not_accepted(self):
        for listing in [LISTING.replace(DIGEST, 'invalid'), LISTING.replace('"\n', '" (CSSMERR_TP_CERT_REVOKED)\n'), 'Developer ID Application: synthetic text without identity row']:
            self.assertEqual(module.check(listing)['signing_status'], 'blocked')

    def test_cli_blocks_without_disclosing_names(self):
        for listing, code in [(LISTING, 0), ('0 valid identities found', 2)]:
            result = subprocess.run(['python3', str(Path(__file__).with_name('check-mac-signing-identity.py'))], input=listing, text=True, capture_output=True)
            self.assertEqual(result.returncode, code)
            self.assertNotIn(NAME, result.stdout)
            self.assertNotIn(DIGEST, result.stdout)
            self.assertEqual(result.stderr, '')


if __name__ == '__main__':
    unittest.main()
