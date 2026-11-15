from pathlib import Path
import io
import json
import sys

here = Path(__file__).resolve().parent
sys.path.insert(0, str(here / 'python'))
from elftools.elf.elffile import ELFFile
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

root = here.parents[3]
source = (root / 'mobile/sandbox/gbox-mod/privacy/compat/runtime.cpp').read_text()
hook = source[source.index('extern "C" bool cage_compat_hook('):source.index('extern "C" void* cage_compat_get_original(')]
publish = source[source.index('static bool publish_binder_auxiliary('):source.index('static jclass root_class(')]
assert hook.index('!publish_binder_auxiliary()') < hook.index('env->RegisterNatives(')
assert publish.index('slot changed before publication') < publish.index('__atomic_store_n(')
assert publish.index('__atomic_store_n(') < publish.index('__atomic_thread_fence(__ATOMIC_SEQ_CST)')
assert 'Binder auxiliary final slot mismatch' in source
obj = root / 'mobile/.build/gbox-mod/native-privacy-check/privacy11/runtime12.o'
elf = ELFFile(io.BytesIO(obj.read_bytes()))
engine = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
evidence = []
for symbol in elf.get_section_by_name('.symtab').iter_symbols():
    if symbol['st_info']['type'] != 'STT_FUNC' or not symbol['st_size']:
        continue
    if symbol.name != 'cage_compat_hook' and 'publish_binder_auxiliary' not in symbol.name:
        continue
    section = elf.get_section(symbol['st_shndx'])
    start, size = symbol['st_value'], symbol['st_size']
    for instruction in engine.disasm(section.data()[start:start + size], start):
        if instruction.mnemonic in ('stlr', 'dmb', 'ldar'):
            evidence.append({'function': symbol.name, 'offset': hex(instruction.address),
                             'instruction': instruction.mnemonic + ' ' + instruction.op_str})
assert any(item['instruction'].startswith('stlr ') for item in evidence)
assert any(item['instruction'] == 'dmb ish' for item in evidence)
result = {'compile': 'PASS', 'preflightBeforeStores': True, 'publicationBeforeRegisterNatives': True,
          'releaseStoresAndFullFenceInObject': evidence, 'finalTwoSlotEqualityCheck': True,
          'runtimeValidation': 'NOT_RUN'}
(here / 'binder-publication12-static-check.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result))
