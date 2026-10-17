#!/usr/bin/env python3
import importlib.util
import io
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('history_archives', Path(__file__).with_name('audit-history-archives.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def zipped(files):
    result = io.BytesIO()
    with zipfile.ZipFile(result, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            archive.writestr(name, data)
    return result.getvalue()


class ArchiveAuditTests(unittest.TestCase):
    def test_safe_package(self):
        self.assertEqual(module.inspect_archive(zipped({'README.md': 'safe', 'app/Assets/icon.png': 'art'})), (False, False, False))

    def test_nested_private_material(self):
        inner = zipped({'config/google-oauth.json': '{}', 'recipient/photo.png': 'synthetic'})
        self.assertEqual(module.inspect_archive(zipped({'dist/package.zip': inner})), (True, True, False))

    def test_oauth_download_name_and_private_archive(self):
        self.assertEqual(module.inspect_archive(zipped({'client_secret_fixture.json': '{}'})), (True, True, False))
        self.assertEqual(module.inspect_archive(zipped({'Geoffrey-Mac-Private-Beta.zip': zipped({'safe': 'x'})})), (True, False, False))

    def test_corrupt_and_bounded_archives_fail_closed(self):
        self.assertEqual(module.inspect_archive(b'not a zip'), (False, False, True))
        data = zipped({'nested.zip': zipped({'safe': 'x'})})
        self.assertTrue(module.inspect_archive(data, depth=module.MAX_DEPTH)[2])
        self.assertTrue(module.inspect_archive(data, budget={'bytes': 1, 'entries': 100})[2])
        self.assertTrue(module.inspect_archive(data, budget={'bytes': 1000, 'entries': 0})[2])

    def test_deleted_historical_bundle_is_still_detected(self):
        with tempfile.TemporaryDirectory() as folder:
            def git(*args):
                return subprocess.check_output(['git', '-C', folder, *args], stderr=subprocess.DEVNULL)
            git('init', '-q')
            git('config', 'user.name', 'Synthetic audit')
            git('config', 'user.email', 'fixture@example.com')
            archive = Path(folder) / 'ordinary-package.zip'
            archive.write_bytes(zipped({'package.zip': zipped({'accounts.json': '{}'})}))
            git('add', '.')
            git('-c', 'commit.gpgsign=false', 'commit', '-qm', 'Fixture')
            archive.unlink()
            git('add', '-u')
            git('-c', 'commit.gpgsign=false', 'commit', '-qm', 'Remove from tip')
            report = module.audit(folder)
            self.assertEqual(report['history_zip_blobs'], 1)
            self.assertEqual(report['history_zip_risky_blobs'], 1)
            self.assertEqual(report['history_zip_credential_path_blobs'], 1)
            self.assertEqual(report['history_zip_uninspected_blobs'], 0)

    def test_shell_gate_clean_direct_nested_and_incomplete(self):
        for kind in ['clean', 'direct', 'nested', 'incomplete']:
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                (root / 'scripts').mkdir()
                for name in ['audit-history-exposure.sh', 'audit-history-archives.py']:
                    shutil.copy(Path(__file__).with_name(name), root / 'scripts' / name)
                def git(*args):
                    return subprocess.check_output(['git', '-C', folder, *args], stderr=subprocess.DEVNULL)
                git('init', '-q')
                git('config', 'user.name', 'Synthetic audit')
                git('config', 'user.email', 'fixture@example.com')
                (root / 'README.md').write_text('safe')
                if kind == 'direct':
                    (root / 'recipient-photo.png').write_bytes(b'synthetic')
                elif kind == 'nested':
                    (root / 'package.zip').write_bytes(zipped({'nested.zip': zipped({'accounts.json': '{}'})}))
                elif kind == 'incomplete':
                    (root / 'package.zip').write_bytes(b'corrupt')
                git('add', '.')
                git('-c', 'commit.gpgsign=false', 'commit', '-qm', 'Fixture')
                result = subprocess.run(['bash', str(root / 'scripts/audit-history-exposure.sh')], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0 if kind == 'clean' else 2, result.stderr)
                expected = 'clean' if kind == 'clean' else 'audit_incomplete' if kind == 'incomplete' else 'rewrite_required'
                self.assertIn('status=' + expected, result.stdout)
                self.assertNotIn('recipient-photo.png', result.stdout)
                self.assertNotIn('accounts.json', result.stdout)


if __name__ == '__main__':
    unittest.main()
