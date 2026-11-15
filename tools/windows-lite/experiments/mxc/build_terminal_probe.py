"""Build a synthetic console; launch is exclusively through the official MXC SDK."""
import argparse, os, subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True)
    root=parser.parse_args().output.resolve()
    binary=root/'bin';binary.mkdir(parents=True,exist_ok=False)
    (root/'data').mkdir()
    program=Path(os.environ.get('ProgramFiles(x86)',r'C:\Program Files (x86)'))
    compiler=Path(subprocess.check_output([str(program/'Microsoft Visual Studio/Installer/vswhere.exe'),'-latest','-products','*','-requires','Microsoft.VisualStudio.Component.VC.Tools.x86.x64','-find',r'VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe'],text=True).strip().splitlines()[0])
    msvc=compiler.parents[3];sdk=program/'Windows Kits/10'
    version=sorted((sdk/'Include').glob('10.*'),key=lambda p:tuple(map(int,p.name.split('.'))))[-1].name
    includes=[msvc/'include',*[sdk/'Include'/version/k for k in ('ucrt','shared','um','winrt')]]
    libs=[msvc/'lib/x64',*[sdk/'Lib'/version/k/'x64' for k in ('ucrt','um')]]
    env=dict(os.environ,INCLUDE=os.pathsep.join(map(str,includes)),LIB=os.pathsep.join(map(str,libs)))
    env['PATH']=str(compiler.parent)+os.pathsep+env.get('PATH','')
    with (root/'build.log').open('w') as log:
        subprocess.run([str(compiler),'/nologo','/O2','/W4','/MT','/D_CRT_SECURE_NO_WARNINGS',str(HERE/'terminal_probe.c'),'/Fe:CageMxcTerminalProbe.exe','/link','advapi32.lib'],cwd=binary,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
    print(root)

if __name__=='__main__':main()
