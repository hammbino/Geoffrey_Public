#!/usr/bin/env python3
"""Explicit reversible login-Keychain proof using uniquely named dummy items only."""
import json
import pathlib
import subprocess
import sys
import uuid

helper = str(pathlib.Path(sys.argv[1]).resolve())
account = "geoffrey-native-proof-" + uuid.uuid4().hex
service = "com.geoffrey.desktop.oauth.v1"
base = ["-s", service, "-a", account]

def run(command, *arguments, value=None):
    return subprocess.run([command, *arguments], input=value, capture_output=True, timeout=20)

try:
    for count in [1024, 4096]:
        value = json.dumps({"schema_version": 1, "fixture": "dummy-value-" * count}).encode()
        result = run(helper, "add-generic-password", "--no-ui", "-U", *base, "-w", value=value)
        assert result.returncode == 0, "Native write failed: " + result.stderr.decode()
        result = run(helper, "find-generic-password", "--no-ui", *base, "-w")
        assert result.returncode == 0 and result.stdout == value, "Native read failed: " + result.stderr.decode()
    deletion = run(helper, "delete-generic-password", "--no-ui", *base)
    assert deletion.returncode == 0, "Native delete failed: " + deletion.stderr.decode()
    assert run(helper, "find-generic-password", "--no-ui", *base, "-w").returncode == 44
    print("native_create_update_read_delete=passed")
finally:
    cleanup = run(helper, "delete-generic-password", "--no-ui", *base)
    assert cleanup.returncode in (0, 44), "Dummy Keychain cleanup failed"
    print("dummy_item_cleanup=passed")
