"""Resume completed Privacy10 compilation and ZIP assembly after metadata staging."""
from pathlib import Path
import json
import shutil
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'mobile/sandbox/gbox-mod'
sys.path.insert(0, str(MODULE))
from build import BUILD, sha

base = ROOT / 'dist/Cage-GBox-Privacy-09.apk'
old_work = BUILD / 'pie61c44'
work = BUILD / 'pj54e69b'
privacy, compat = work / 'privacy', work / 'compat'
classes, dex = privacy / 'classes', privacy / 'dex'
compat_library = compat / 'libcage_compat.so'
native_source = BUILD / 'native-privacy-check/privacy-native'
native_output = work / 'privacy-native'
native_library = native_output / 'libcage_privacy.so'
replacement = {'classes10.dex': dex / 'classes.dex',
               'lib/arm64-v8a/libcage_privacy.so': native_library,
               'lib/arm64-v8a/libcage_compat.so': compat_library}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk') as output:
    for name, path in replacement.items():
        if source.read(name) == path.read_bytes() or output.read(name) != path.read_bytes():
            raise ValueError('Unexpected replacement contents: ' + name)
changed_classes = []
for file in sorted(classes.rglob('*.class')):
    relative = file.relative_to(classes)
    previous = old_work / 'privacy/classes' / relative
    if not previous.exists() or file.read_bytes() != previous.read_bytes():
        changed_classes.append(relative.as_posix())
source = (BUILD / 'prepare_privacy10.py').read_text('utf-8')
exec(compile(source[source.index('boundary = {'):], str(BUILD / 'prepare_privacy10.py'), 'exec'))
