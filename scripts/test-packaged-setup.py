#!/usr/bin/env python3
"""Exercise the delivered engine with only its own tools and macOS utilities.
No OAuth, Keychain operations, remote repositories, or existing user state.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

engine = pathlib.Path(sys.argv[1]).resolve() / 'Contents/Resources/GeoffreyEngine'
with tempfile.TemporaryDirectory(prefix='geoffrey-packaged-setup-') as folder:
    home = pathlib.Path(folder)
    env = {**os.environ, 'HOME': folder, 'PATH': '/usr/bin:/bin:/usr/sbin:/sbin',
           'GIT_CONFIG_GLOBAL': '/dev/null', 'GIT_CONFIG_NOSYSTEM': '1',
           'GIT_EXEC_PATH': str(engine / 'runtime/git-core'),
           'GIT_TEMPLATE_DIR': str(engine / 'runtime/git-template')}
    def command(*args):
        result = subprocess.run([str(engine / 'bin/geoffrey'), *args], env=env,
                                capture_output=True, text=True, input='', timeout=30)
        assert result.returncode == 0, (args, result.stdout, result.stderr)
        return result.stdout
    for tool in ('node', 'claude', 'gh', 'git'):
        subprocess.run([str(engine / 'runtime/bin' / tool), '--version'], env=env,
                       check=True, capture_output=True, timeout=30)
    assert os.access(engine / 'runtime/git-core/git-credential-osxkeychain', os.X_OK)
    subprocess.run([str(engine / 'runtime/bin/node'), '--input-type=module', '-e',
                    'await import("@modelcontextprotocol/sdk/server/mcp.js")'],
                   cwd=engine / 'geoffrey-mcp', env=env, check=True, capture_output=True, timeout=30)
    command('app-migrate')
    command('memory', '--name', 'Packaged Fixture', '--business', 'Personal', '--local')
    memory = home / 'Geoffrey'
    assert (home / '.geoffrey/current-memory').read_text().strip() == str(memory)
    assert memory.stat().st_mode & 0o777 == 0o700
    assert (memory / 'memory/user.md').exists()
    assert (memory / 'memory/skills/daily-briefing.md').exists()
    assert 'PRIVATE GEOFFREY CONTEXT' in command('app-context', '--task', 'capability-review')
    assert json.loads(command('app-sync-status'))['state'] == 'local_only'
    # A fresh invocation models relaunch: the same pointer and local memory survive.
    assert json.loads(command('app-sync'))['state'] == 'local_only'
    assert (home / '.geoffrey/current-memory').stat().st_mode & 0o777 == 0o600
    assert json.loads(command('app-accounts')) == []
    print('Packaged first-use local memory passes without Homebrew, npm, GitHub login, or developer PATH')
