#!/usr/bin/env python3
"""Copy installed native tools and their dylib closure into an isolated runtime.

No network or package installation. Explicit paths may be supplied for release
builds; every dependency is relocated and signed, never resolved via Homebrew
on the recipient's Mac. The bundle's OS minimum follows its actual binaries.
"""
import os
import pathlib
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

app = pathlib.Path(sys.argv[1]).resolve()
runtime = app / 'Contents/Resources/GeoffreyEngine/runtime'
bindir = runtime / 'bin'
libdir = runtime / 'lib'
for name in ('bin', 'lib', 'git-core', 'git-template', 'licenses'):
    (runtime / name).mkdir(parents=True, exist_ok=True)
identity = os.environ.get('GEOFFREY_CODESIGN_IDENTITY', '-')
copied = {}
minimum = (14, 0)

def output(*args):
    return subprocess.check_output(args, text=True)

def system(path):
    return path.startswith(('/usr/lib/', '/System/Library/'))

def relocate(source, target):
    global minimum
    source = pathlib.Path(source).resolve()
    if target in copied:
        if copied[target] != source:
            raise RuntimeError('Runtime library name collision: ' + target.name)
        return
    copied[target] = source
    shutil.copy2(source, target)
    target.chmod(0o755)
    loads = output('/usr/bin/otool', '-l', str(source))
    for version in re.findall(r'\bminos ([0-9.]+)', loads):
        minimum = max(minimum, tuple(map(int, version.split('.')[:2])))
    rpaths = re.findall(r'cmd LC_RPATH\n\s*cmdsize \d+\n\s*path (.*?) \(offset', loads)
    def expand(value):
        return value.replace('@loader_path', str(source.parent)).replace('@executable_path', str(source.parent))
    dependencies = output('/usr/bin/otool', '-L', str(source)).splitlines()[1:]
    for entry in dependencies:
        original = entry.strip().split(' (compatibility')[0]
        if system(original):
            continue
        if original.startswith('@rpath/'):
            candidates = [pathlib.Path(expand(p)) / original[len('@rpath/'):] for p in rpaths]
            found = next((p for p in candidates if p.exists()), None)
        else:
            found = pathlib.Path(expand(original))
        if not found or not found.exists():
            raise RuntimeError(f'Cannot resolve runtime dependency {original} in {source.name}')
        if found.resolve() == source:  # dylib's own install name
            subprocess.run(['/usr/bin/install_name_tool', '-id', '@rpath/' + target.name, str(target)], check=True, capture_output=True)
            continue
        destination = libdir / found.name
        relocate(found, destination)
        new = '@loader_path/' + os.path.relpath(destination, target.parent)
        subprocess.run(['/usr/bin/install_name_tool', '-change', original, new, str(target)], check=True, capture_output=True)
    # Carry package license notices where the installed package supplies them.
    for parent in [source.parent, *list(source.parents)[:4]]:
        for notice in parent.glob('LICENSE*'):
            if notice.is_file():
                name = parent.name + '-' + notice.name
                shutil.copy2(notice, runtime / 'licenses' / name)
    signing = ['/usr/bin/codesign', '--force', '--sign', identity]
    if identity != '-':
        signing += ['--options', 'runtime', '--timestamp']
    with tempfile.TemporaryDirectory(prefix='geoffrey-runtime-sign-') as temporary:
        if target.parent == bindir and target.name in ('node', 'claude'):
            entitlements = pathlib.Path(temporary) / 'entitlements.plist'
            with entitlements.open('wb') as f:
                plistlib.dump({'com.apple.security.cs.allow-jit': True,
                              'com.apple.security.cs.allow-unsigned-executable-memory': True}, f)
            signing += ['--entitlements', str(entitlements)]
        subprocess.run([*signing, str(target)], check=True, capture_output=True)

for tool in ('node', 'claude', 'gh', 'git'):
    source = os.environ.get('GEOFFREY_RUNTIME_' + tool.upper()) or shutil.which(tool)
    if not source:
        raise RuntimeError(f'Cannot build a self-contained app: {tool} is missing on the build machine')
    relocate(source, bindir / tool)
    if tool == 'git':
        git_core = pathlib.Path(output(source, '--exec-path').strip())
        for helper in ('git-remote-http', 'git-remote-https', 'git-credential-osxkeychain'):
            relocate(git_core / helper, runtime / 'git-core' / helper)

# Prove relocation with no developer PATH; no auth or network operations.
env = {**os.environ, 'PATH': str(bindir) + ':/usr/bin:/bin',
       'GIT_EXEC_PATH': str(runtime / 'git-core'), 'GIT_TEMPLATE_DIR': str(runtime / 'git-template')}
for tool in ('node', 'claude', 'gh', 'git'):
    subprocess.run([str(bindir / tool), '--version'], env=env, check=True, stdout=subprocess.DEVNULL, timeout=30)
for target in copied:
    for entry in output('/usr/bin/otool', '-L', str(target)).splitlines()[1:]:
        dependency = entry.strip().split(' (compatibility')[0]
        if not (system(dependency) or dependency.startswith(('@loader_path/', '@rpath/'))):
            raise RuntimeError('Nonportable runtime dependency: ' + dependency)
plist_path = app / 'Contents/Info.plist'
with plist_path.open('rb') as f:
    plist = plistlib.load(f)
plist['LSMinimumSystemVersion'] = '.'.join(map(str, minimum))
with plist_path.open('wb') as f:
    plistlib.dump(plist, f)
print(f'Bundled {len(copied)} runtime binaries; minimum macOS {plist["LSMinimumSystemVersion"]}')
