"""One-time typed source generation from the independently reviewed inventory.

The generated include is the build input. This helper does not modify GBox,
touch devices, or download anything.
"""
import json
from pathlib import Path
import sys

inventory = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
methods = inventory["methods"]
assert len(methods) == 17
kind = {"jint": "I", "jlong": "J", "jboolean": "Z"}
out = ["// Generated from native-hook-inventory-api31-32.json; reviewed exact JNI signatures."]

def declaration(method):
    receiver = "jclass" if method["static"] else "jobject receiver"
    params = ["JNIEnv* env", receiver]
    params += [f"{type_name} p{i}" for i, type_name in enumerate(method["javaParameterTypes"])]
    return f"static {method['jniReturnType']} adapt_{method['id']}({', '.join(params)})"

for method in methods:
    if method["id"] != "binder_uid":
        out.append(declaration(method) + ";")
out.append("\nstatic Hook hooks[] = {")
for method in methods:
    fields = [json.dumps(method[key]) for key in ("id", "class", "name", "signature")]
    fields.append(json.dumps("".join(kind.get(t, "L") for t in method["javaParameterTypes"])))
    fields += [str(value).lower() for value in (
        method["static"], method["id"] != "property_get_single", method["id"] == "binder_uid",
        method["api31_32_AospExpectedInstalled"])]
    fields += [method["callback"], method["originalSlot"], "nullptr" if method["id"] == "binder_uid" else f"(void*)&adapt_{method['id']}"]
    out.append("    {" + ", ".join(fields) + "},")
out.append("};\n")
for index, method in enumerate(methods):
    if method["id"] == "binder_uid":
        continue
    out.append(declaration(method) + " {")
    params = method["javaParameterTypes"]
    if params:
        out.append(f"    jvalue values[{len(params)}] = {{}};")
        for i, type_name in enumerate(params):
            out.append(f"    values[{i}].{kind.get(type_name, 'L').lower()} = p{i};")
    args = "values" if params else "nullptr"
    receiver = "nullptr" if method["static"] else "receiver"
    out.append(f"    jobject result = invoke_backup(env, hooks[{index}], {receiver}, {args});")
    return_type = method["jniReturnType"]
    if return_type == "void":
        out.append("    if (result) env->DeleteLocalRef(result);")
    elif return_type in ("jint", "jlong", "jboolean"):
        out.append(f"    return unbox_{return_type[1:]}(env, result);")
    else:
        assert return_type == "jstring"
        out.append("    return (jstring)result;")
    out.append("}\n")
Path(__file__).with_name("typed_adapters.inc").write_text("\n".join(out), encoding="utf-8")
print("Generated 17 method records and 16 typed ordinary JNI adapters")
