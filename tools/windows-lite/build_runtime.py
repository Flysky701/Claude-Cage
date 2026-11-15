"""Build Cage-owned x64 runtime helpers without changing installed components."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

HERE=Path(__file__).resolve().parent

def build(output):
    output.mkdir(parents=True,exist_ok=True)
    program=Path(os.environ.get("ProgramFiles(x86)",r"C:\Program Files (x86)"))
    locate=program/"Microsoft Visual Studio/Installer/vswhere.exe"
    found=subprocess.check_output([str(locate),"-latest","-products","*","-requires","Microsoft.VisualStudio.Component.VC.Tools.x86.x64","-find",r"VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe"],text=True)
    compiler=Path(found.strip().splitlines()[0]);msvc=compiler.parents[3]
    sdk=program/"Windows Kits/10"
    version=sorted((sdk/"Include").glob("10.*"),key=lambda p:tuple(map(int,p.name.split('.'))))[-1].name
    includes=[msvc/"include",*[sdk/"Include"/version/k for k in ("ucrt","shared","um","winrt")]]
    libs=[msvc/"lib/x64",*[sdk/"Lib"/version/k/"x64" for k in ("ucrt","um")]]
    env=dict(os.environ,INCLUDE=os.pathsep.join(map(str,includes)),LIB=os.pathsep.join(map(str,libs)))
    env["PATH"]=str(compiler.parent)+os.pathsep+env.get("PATH","")
    commands=[([HERE/"runtime_native.c"],"CageRuntime.exe",[]),([HERE/"runtime_connect.c"],"CageConnect.dll",["/LD"])]
    if (HERE/"terminal_bridge.c").is_file():commands.append(([HERE/"terminal_bridge.c"],"CageTerminal.exe",[]))
    with (output/"build.log").open("w",encoding="utf-8") as log:
        for sources,name,flags in commands:
            link=["/SUBSYSTEM:WINDOWS","/ENTRY:wmainCRTStartup"] if name.endswith(".exe") else []
            subprocess.run([str(compiler),"/nologo","/O2","/W4","/MT","/D_CRT_SECURE_NO_WARNINGS",*flags,*map(str,sources),"/Fe:"+name,"/link",*link,"ws2_32.lib","winhttp.lib","shell32.lib","advapi32.lib"],cwd=output,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,creationflags=getattr(subprocess,"CREATE_NO_WINDOW",0))
    names=[name for sources,name,flags in commands]
    manifest={"version":1,"sha256":{n:hashlib.sha256((output/n).read_bytes()).hexdigest() for n in names},"sourceSha256":{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (HERE/"runtime_native.c",HERE/"runtime_connect.c",HERE/"runtime_dns.c",HERE/"terminal_bridge.c") if p.is_file()}}
    (output/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
    return manifest

if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--output",type=Path,required=True)
    print(json.dumps(build(parser.parse_args().output.resolve())))
