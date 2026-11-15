"""Add the current privacy overlay to tested Trace06, reusing its core/compat."""
from pathlib import Path
import importlib.util
import json
import os
import shutil
import sys
import uuid
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'mobile/sandbox/gbox-mod'
sys.path.insert(0, str(MODULE))
from build import BUILD, run, signature_entry, sha

base = ROOT / 'dist/Cage-GBox-Native-Trace-06.apk'
old_work = BUILD / 'f256815b'
work = BUILD / ('p' + uuid.uuid4().hex[:7])
work.mkdir()
decoded = work / 'd'
shutil.copytree(old_work / 'd/smali_classes4', decoded / 'smali_classes4')
for number in (1, 2, 3, 5, 6, 7, 8, 9):
    (decoded / ('smali' if number == 1 else f'smali_classes{number}')).mkdir()
with ZipFile(base) as archive:
    if archive.read('classes4.dex') != (old_work / 'classes4.dex').read_bytes():
        raise ValueError('Trace06 DEX source cache mismatch')
    if 'classes10.dex' in archive.namelist():
        raise ValueError('Unexpected existing privacy DEX')
    (decoded / 'AndroidManifest.xml').write_bytes(archive.read('AndroidManifest.xml'))
jdk = Path('D:/Code/DevEnv/JAVA/jdk-17')
tools = ROOT / 'mobile/.build/client-integration/build-tools35/android-15'
apktool = ROOT / 'mobile/.build/blackbox-source/apktool.jar'
context = {'root': ROOT, 'jdk': jdk, 'tools': tools, 'apktool': apktool,
           'android_jar': ROOT / 'mobile/.build/gbox-test/android.jar',
           'env': dict(os.environ, JAVA_HOME=str(jdk)), 'run': run,
           'native_trace': True,
           'privacy_modules': ['sim', 'timezone', 'vpn'], 'privacy_timezone': 'Asia/Tokyo'}
spec = importlib.util.spec_from_file_location('privacy_overlay', MODULE / 'privacy/apply.py')
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)
overlay = privacy.apply(decoded, work, context)
expected_extra = {'lib/arm64-v8a/libcage_privacy.so', 'assets/cage-child/x86_64/libcage_child_properties.so'}
if set(overlay['extra_entries']) != expected_extra or overlay['changed_dex'] != ['classes4.dex', 'classes10.dex']:
    raise ValueError('Unexpected privacy overlay shape')
core = decoded / 'smali_classes4/com/vlite/sdk'
g7 = (core / 'ІӀӏ/g7.smali').read_text('utf-8')
pm = (core / 'client/hook/service/pm/a$m.smali').read_text('utf-8')
client = (core / 'client/k.smali').read_text('utf-8')
instrumentation = (core / 'client/hook/service/app/InstrumentationLiteApp.smali').read_text('utf-8')
assert g7.count('.method public invoke(') == 1 and g7.count('.method public cageOriginalInvoke(') == 1
assert pm.count('.method public varargs b(') == 1 and pm.count('.method public varargs cageFrameworkOriginalQuery(') == 1
assert client.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->bind(') == 1
bind = client.index('Lio/github/leexeo/cage/privacy/GuestPrivacy;->bind(')
context_call = client.index('invoke-virtual {v6, v14, v15}, Landroid/content/Context;->createPackageContext(')
framework_bind = client.index('Lio/github/leexeo/cage/gbox/FrameworkPaths;->bind(')
assert framework_bind < context_call < bind < client.index('->makeApplication:')
assert instrumentation.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->bind(') == 2
assert instrumentation.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->apply(') == 2
assert client.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->apply(') == 1
assert client.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->beforeBind(') == 2
assert client.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->rethrowIfBlocked(') == 2
assert instrumentation.count('Lio/github/leexeo/cage/privacy/GuestPrivacy;->rethrowIfBlocked(') == 1
for signature in ('.method public bindApplication(Ljava/lang/String;Ljava/lang/String;)V',
                  '.method public final s0(Ljava/lang/String;Ljava/lang/String;)V'):
    start = client.index(signature)
    section = client[start:client.index('.end method', start)]
    guard = section.index('->beforeBind(')
    assert guard < section.index('->u0(')
    assert guard < section.index(':try_start_0')
published = client.index('invoke-virtual {v5, v7, v3}, Lcom/vlite/sdk/reflect/e;->set(Ljava/lang/Object;Ljava/lang/Object;)V')
assert published < client.index('Lio/github/leexeo/cage/privacy/GuestPrivacy;->apply(')
replacement = {}
for name in overlay['changed_dex']:
    print('Assembling ' + name, flush=True)
    path = work / name
    run(jdk / 'bin/java.exe', '-cp', apktool, MODULE / 'AssembleDex.java', decoded / ('smali_' + name[:-4]), path, '28')
    replacement[name] = path.read_bytes()
with ZipFile(base) as source, ZipFile(work / 'unsigned.apk', 'w') as output:
    for entry in source.infolist():
        if not signature_entry(entry.filename):
            output.writestr(entry, replacement.get(entry.filename, source.read(entry.filename)))
    output.writestr('classes10.dex', replacement['classes10.dex'])
    for name, path in overlay['extra_entries'].items():
        if name in source.namelist():
            raise ValueError('Privacy overlay unexpectedly replaces an original asset: ' + name)
        output.write(path, name)
(work / 'compat').mkdir()
metadata = json.loads((old_work / 'compat/metadata.json').read_text('utf-8'))
metadata['frameworkPathAdapter'].pop('offlineValidation', None)
metadata['nativeAndCompatDexReusedFrom'] = 'dist/Cage-GBox-Native-Trace-06.apk'
metadata['deviceValidation'] = 'NOT_RUN_FOR_COMBINED_PRIVACY_BUILD'
(work / 'compat/metadata.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
shutil.copyfile(old_work / 'native-trace.json', work / 'native-trace.json')
validation = {'base': str(base.relative_to(ROOT)), 'baseSha256': sha(base),
              'changedExistingDex': ['classes4.dex'], 'addedDex': ['classes10.dex'],
              'g7AndPmOriginalCallWrappersUnique': True,
              'guestPrivacyBindAfterContextBeforeApplication': True,
              'instrumentationBindAndActivityRefreshPreserved': True,
              'privacyRefreshAfterInitialApplicationPublication': True,
              'blockedProcessGuardBeforeCacheAndOriginalTry': True,
              'blockedExceptionsNotConsumedByOriginalFallbackOrInstrumentation': True,
              'ordinaryExceptionHandlingAndProcessExitPolicyUnchanged': True,
              'existingNativeLibrariesAndCompatDexReused': True,
              'addedEntries': sorted(overlay['extra_entries']),
              'hostNativeAbisUnchanged': True,
              'privacyModules': ['sim', 'timezone', 'vpn'], 'timezone': 'Asia/Tokyo',
              'privacyRuntimeAcceptance': 'NOT_RUN', 'loginVerified': False}
(work / 'combined-integration.json').write_text(json.dumps(validation, indent=2), encoding='utf-8')
print(str(work / 'unsigned.apk'), flush=True)
