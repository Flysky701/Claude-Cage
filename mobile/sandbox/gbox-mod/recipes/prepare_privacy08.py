"""Privacy08: explicit guest Context binding; all native libraries reuse Privacy07."""
from pathlib import Path
import argparse
import json
import os
import shutil
import struct
import sys
import uuid
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'mobile/sandbox/gbox-mod'
sys.path.insert(0, str(MODULE))
from build import BUILD, run, signature_entry, sha

parser = argparse.ArgumentParser()
parser.add_argument('--prepare-only', action='store_true')
parser.add_argument('--work', type=Path)
args = parser.parse_args()
base = ROOT / 'dist/Cage-GBox-Privacy-07.apk'
old_work = BUILD / 'pgaffc72'
dex4_work = BUILD / 'pd9805f7'
compat_work = BUILD / 'f256815b'
jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
android = ROOT / 'mobile/.build/gbox-test/android.jar'
apktool = ROOT / 'mobile/.build/blackbox-source/apktool.jar'
env = dict(os.environ, JAVA_HOME=str(jdk))

def make_dex(classes, directory):
    directory.mkdir()
    jar = directory.parent / 'classes.jar'
    with ZipFile(jar, 'w') as archive:
        for file in sorted(classes.rglob('*.class')):
            archive.write(file, file.relative_to(classes).as_posix())
    run(tools / 'd8.bat', '--min-api', '28', '--lib', android, '--output', directory, jar, env=env)
    return directory / 'classes.dex'

if args.work is None:
    work = BUILD / ('ph' + uuid.uuid4().hex[:6])
    decoded = work / 'd'
    shutil.copytree(dex4_work / 'd/smali_classes4', decoded / 'smali_classes4')
    with ZipFile(base) as source:
        assert source.read('classes4.dex') == (dex4_work / 'classes4.dex').read_bytes()
        assert source.read('classes8.dex') == (compat_work / 'classes8.dex').read_bytes()
    client = decoded / 'smali_classes4/com/vlite/sdk/client/k.smali'
    source = client.read_text('utf-8')
    old = ('    move-result-object v4\n\n'
        '    invoke-static {}, Lcom/vlite/sdk/client/k;->cagePrivacyBindBefore()V\n'
        '    invoke-static {v4}, Lio/github/leexeo/cage/privacy/GuestPrivacy;->bind(Landroid/content/Context;)V\n'
        '    invoke-static {}, Lcom/vlite/sdk/client/k;->cagePrivacyBindAfter()V\n'
        '    invoke-static {}, Lio/github/leexeo/cage/gbox/NativeTrace;->stage13()V\n'
        '    invoke-static {v4}, Lio/github/leexeo/cage/gbox/FrameworkPaths;->contextCreated(Landroid/content/Context;)V')
    new = ('    move-result-object v4\n'
        '    invoke-static {}, Lio/github/leexeo/cage/gbox/NativeTrace;->stage13()V\n'
        '    invoke-static {v4}, Lio/github/leexeo/cage/gbox/FrameworkPaths;->contextCreated(Landroid/content/Context;)V\n\n'
        '    invoke-static {}, Lcom/vlite/sdk/client/k;->cagePrivacyBindBefore()V\n'
        '    invoke-static {v4}, Lio/github/leexeo/cage/privacy/GuestPrivacy;->bindGuestContext(Landroid/content/Context;)V\n'
        '    invoke-static {}, Lcom/vlite/sdk/client/k;->cagePrivacyBindAfter()V')
    assert source.count(old) == 1
    source = source.replace(old, new)
    client.write_text(source, encoding='utf-8', newline='\n')
    call = source.index('invoke-virtual {v6, v14, v15}, Landroid/content/Context;->createPackageContext(')
    observed = source.index('->contextCreated(Landroid/content/Context;)V', call)
    bind = source.index('->bindGuestContext(Landroid/content/Context;)V', call)
    assert call < observed < bind < source.index('->makeApplication:', call)
    assert source.count('GuestPrivacy;->bind(') == 0
    assert source.count('GuestPrivacy;->bindGuestContext(') == 1
    instrumentation = (decoded / 'smali_classes4/com/vlite/sdk/client/hook/service/app/InstrumentationLiteApp.smali').read_text('utf-8')
    assert instrumentation.count('GuestPrivacy;->bind(') == 2
    assert 'GuestPrivacy;->bindGuestContext(' not in instrumentation
    run(jdk / 'bin/java.exe', '-cp', apktool, MODULE / 'AssembleDex.java', decoded / 'smali_classes4', work / 'classes4.dex', '28')

    compat = work / 'compat'
    shutil.copytree(compat_work / 'compat/classes', compat / 'classes')
    run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-cp', android,
        '-d', compat / 'classes', MODULE / 'compat/NativeCompat.java', MODULE / 'compat/FrameworkPaths.java', env=env)
    make_dex(compat / 'classes', compat / 'dex')
    check = work / 'state-check'
    check.mkdir()
    classpath = os.pathsep.join((str(android), str(compat / 'classes')))
    run(jdk / 'bin/javac.exe', '--release', '8', '-cp', classpath, '-d', check, BUILD / 'NativeCompatStateCheck.java', env=env)
    report = run(jdk / 'bin/java.exe', '-cp', classpath + os.pathsep + str(check), 'NativeCompatStateCheck', env=env)
    (work / 'state-check.txt').write_text(report, encoding='utf-8')
    assert 'PASS preparation state cases=6 readOnly=true' in report
    (work / 'prepared.json').write_text(json.dumps({'baseSha256': sha(base), 'stateCases': 6,
        'contextObservationBeforeFullBinding': True, 'instrumentationFullBindingCalls': 0}), encoding='utf-8')
else:
    work = args.work.resolve()
    assert work.is_relative_to(BUILD.resolve())
    assert json.loads((work / 'prepared.json').read_text('utf-8'))['baseSha256'] == sha(base)

if args.prepare_only:
    print(str(work))
    raise SystemExit(0)

privacy = work / 'privacy'
shutil.copytree(old_work / 'privacy/classes', privacy / 'classes')
shutil.copytree(old_work / 'privacy/generated', privacy / 'generated')
run(jdk / 'bin/javac.exe', '--release', '8', '-encoding', 'UTF-8', '-g',
    '-cp', os.pathsep.join((str(android), str(privacy / 'classes'))), '-d', privacy / 'classes',
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/GuestPrivacy.java',
    MODULE / 'privacy/java/io/github/leexeo/cage/privacy/NativePrivacy.java', env=env)
make_dex(privacy / 'classes', privacy / 'dex')
replacement = {'classes4.dex': work / 'classes4.dex', 'classes8.dex': work / 'compat/dex/classes.dex',
               'classes10.dex': privacy / 'dex/classes.dex'}
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            output.writestr(entry, replacement[entry.filename].read_bytes() if entry.filename in replacement else source.read(entry.filename))

metadata = json.loads((old_work / 'privacy/metadata.json').read_text('utf-8'))
metadata.update(guestBind='Only bindGuestContext after actual guest Context return and Framework context observation',
    instrumentationBind='Refresh an already bound same-guest policy only; never initializes from an early Context',
    preparationGate='Absent compatibility class or explicit original path: Context identity; verified compatibility: matching Framework roots; pending/failed: no policy initialization')
metadata['webView']['runtimeFirstScriptValidation'] = 'NOT_RUN for Privacy08; helper bytecode reused from Privacy07'
metadata['fixedPolicyStageDiagnostics']['legacyMarkerCaveat'] = 'Privacy08 moves after.createPackageContext to the actual return before Framework observation and full privacy binding'
(privacy / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
compat_metadata = json.loads((old_work / 'compat/metadata.json').read_text('utf-8'))
compat_metadata.pop('nativeAndCompatDexReusedFrom', None)
compat_metadata['nativeLibraryReusedFrom'] = 'dist/Cage-GBox-Privacy-07.apk'
compat_metadata['privacyReadinessQuery'] = {'readOnly': True, 'stateCasesChecked': 6,
    'originalPathPreserved': True, 'verifiedContextUsesExistingGuestRoots': True}
(work / 'compat/metadata.json').write_text(json.dumps(compat_metadata, indent=2), encoding='utf-8')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = json.loads((old_work / 'combined-integration.json').read_text('utf-8'))
for key in ('guardFixes', 'changedJavaClasses'):
    validation.pop(key, None)
validation.update(base=str(base.relative_to(ROOT)), baseSha256=sha(base),
    changedExistingEntries=sorted(replacement), changedExistingDex=sorted(replacement),
    addedEntries=[], diagnosticsOnly=False, allNativeLibrariesReused=True,
    existingNativeLibrariesAndCompatDexReused=False, existingCoreAndCompatAndTraceDexReused=False,
    coreAndTraceDexReused=True, compatibilityJavaOnlyChanged=True,
    classes4MethodIds=struct.unpack_from('<I', (work / 'classes4.dex').read_bytes(), 88)[0],
    fullBindOnlyAfterGuestContext=True, instrumentationRefreshOnly=True,
    nativePreparationStateCases=6, privacyRuntimeAcceptance='NOT_RUN', loginVerified=False)
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'))
