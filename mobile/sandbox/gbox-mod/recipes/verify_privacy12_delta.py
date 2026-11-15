from pathlib import Path
import json
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'mobile/sandbox/gbox-mod'))
from build import signature_entry

work = ROOT / json.loads((ROOT / 'mobile/.build/gbox-mod/privacy12-work.json').read_text('utf-8'))['work']
artifact = ROOT / 'dist/Cage-GBox-Privacy-12.apk'
with ZipFile(ROOT / 'dist/Cage-GBox-Privacy-11.apk') as source, ZipFile(artifact) as output:
    previous = {name for name in source.namelist() if not signature_entry(name)}
    current = {name for name in output.namelist() if not signature_entry(name)}
    assert previous == current
    changes = sorted(name for name in previous if source.read(name) != output.read(name))
    assert changes == ['lib/arm64-v8a/libcage_compat.so'], changes
integration = json.loads((work / 'combined-integration.json').read_text('utf-8'))
integration['signedEntryDeltaVerified'] = True
(work / 'combined-integration.json').write_text(json.dumps(integration, indent=2), encoding='utf-8')
record = json.loads(artifact.with_suffix('.json').read_text('utf-8'))
record['combinedIntegration'] = integration
artifact.with_suffix('.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'artifact': str(artifact), 'sha256': record['artifactSha256'],
                  'changed': changes, 'buildDirectory': record['buildDirectory']}))
