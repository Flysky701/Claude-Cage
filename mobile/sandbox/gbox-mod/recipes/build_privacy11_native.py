from pathlib import Path
import importlib.util
import json
import os
import subprocess

root = Path(__file__).resolve().parents[4]
source = root / 'mobile/sandbox/gbox-mod/privacy'
work = Path(__file__).resolve().parent / 'privacy11'
work.mkdir(exist_ok=True)
def run(*args, env=None):
    result = subprocess.run([str(arg) for arg in args], capture_output=True, env=env)
    output = (result.stdout + result.stderr).decode('utf-8', errors='replace')
    if result.returncode:
        raise RuntimeError(output)
    return output

spec = importlib.util.spec_from_file_location('parent_native', source / 'native/build.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
build = module.build(work, {'root': root, 'run': run, 'env': dict(os.environ)})
llvm = root / 'mobile/.build/client-integration/ndk/toolchains/llvm/prebuilt/windows-x86_64'
run(llvm / 'bin/clang++.exe', '-fintegrated-cc1', '--target=aarch64-linux-android28',
    '--sysroot=' + str(llvm / 'sysroot'), '-resource-dir=' + str(llvm / 'lib/clang/18'),
    '-std=c++17', '-O2', '-fPIC', '-fno-exceptions', '-fno-rtti', '-fvisibility=hidden',
    '-mno-outline-atomics', '-Wall', '-Wextra', '-Werror',
    '-I' + str(source.parent / 'compat'), '-I' + str(work), '-c', source / 'compat/runtime.cpp',
    '-o', work / 'runtime.o')
previous = root / 'mobile/.build/gbox-mod/c5a628d3/compat/runtime.o'
comparison = {'runtimeObjectMatchesPre10': previous.read_bytes() == (work / 'runtime.o').read_bytes(),
              'parentBuild': 'PASS', 'runtimeCompile': 'PASS'}
(work / 'build-result.json').write_text(json.dumps(comparison, indent=2) + '\n')
print(json.dumps(comparison))
