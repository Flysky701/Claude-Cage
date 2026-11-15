from pathlib import Path
import json
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'mobile/sandbox/gbox-mod'))
from build import signature_entry

work = ROOT / json.loads((ROOT / 'mobile/.build/gbox-mod/privacy11-work.json').read_text('utf-8'))['work']
artifact = ROOT / 'dist/Cage-GBox-Privacy-11.apk'
with ZipFile(ROOT / 'dist/Cage-GBox-Privacy-10.apk') as source, ZipFile(artifact) as output:
    previous = {name for name in source.namelist() if not signature_entry(name)}
    current = {name for name in output.namelist() if not signature_entry(name)}
    assert not previous - current
    added = sorted(current - previous)
    assert added == ['assets/cage-host/host-bridge.dex', 'assets/cage-host/x86_64/libcage_host_load_bridge.so'], added
    changes = sorted(name for name in previous if source.read(name) != output.read(name))
    assert changes == ['classes10.dex', 'lib/arm64-v8a/libcage_compat.so', 'lib/arm64-v8a/libcage_privacy.so'], changes
    native_abis = sorted({name.split('/')[1] for name in current if name.startswith('lib/') and name.endswith('.so')})
    assert native_abis == sorted({name.split('/')[1] for name in previous if name.startswith('lib/') and name.endswith('.so')})
    assert 'x86_64' not in native_abis
    with ZipFile(ROOT / 'dist/Cage-GBox-Privacy-09.apk') as original_compat:
        assert output.read('lib/arm64-v8a/libcage_compat.so') == original_compat.read('lib/arm64-v8a/libcage_compat.so')
integration = json.loads((work / 'combined-integration.json').read_text('utf-8'))
integration['signedEntryDeltaVerified'] = True
integration['changedExistingEntries'] = changes
integration['addedEntries'] = added
integration['hostApkNativeAbis'] = native_abis
integration['originalCompatibilityLibraryByteIdentityVerified'] = True
(work / 'combined-integration.json').write_text(json.dumps(integration, indent=2), encoding='utf-8')
record = json.loads(artifact.with_suffix('.json').read_text('utf-8'))
record['combinedIntegration'] = integration
artifact.with_suffix('.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'artifact': str(artifact), 'sha256': record['artifactSha256'], 'changes': changes,
                  'added': added, 'nativeAbis': native_abis, 'buildDirectory': record['buildDirectory']}))
