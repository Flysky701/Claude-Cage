"""Build and run only Cage's synthetic AppContainer feasibility executable."""
import argparse,hashlib,json,os,subprocess,uuid
from datetime import datetime
from pathlib import Path

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
NO_WINDOW=getattr(subprocess,'CREATE_NO_WINDOW',0)

def build(directory):
    program=Path(os.environ.get('ProgramFiles(x86)',r'C:\Program Files (x86)'))
    locate=program/'Microsoft Visual Studio/Installer/vswhere.exe'
    found=subprocess.check_output([str(locate),'-latest','-products','*','-requires','Microsoft.VisualStudio.Component.VC.Tools.x86.x64','-find',r'VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe'],text=True)
    compiler=Path(found.strip().splitlines()[0]);msvc=compiler.parents[3]
    sdk=program/'Windows Kits/10';version=sorted((sdk/'Include').glob('10.*'),key=lambda p:tuple(map(int,p.name.split('.'))))[-1].name
    includes=[msvc/'include',*[sdk/'Include'/version/k for k in ('ucrt','shared','um','winrt')]]
    libs=[msvc/'lib/x64',*[sdk/'Lib'/version/k/'x64' for k in ('ucrt','um')]]
    env=dict(os.environ,INCLUDE=os.pathsep.join(map(str,includes)),LIB=os.pathsep.join(map(str,libs)))
    env['PATH']=str(compiler.parent)+os.pathsep+env.get('PATH','')
    with (directory/'build.log').open('w',encoding='utf-8') as log:
        subprocess.run([str(compiler),'/nologo','/O2','/W4','/MT','/D_CRT_SECURE_NO_WARNINGS',str(HERE/'probe.c'),'/Fe:CageAppContainerProbe.exe','/link','advapi32.lib','userenv.lib'],cwd=directory,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=NO_WINDOW,check=True)
    return directory/'CageAppContainerProbe.exe'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--build-only',action='store_true');args=parser.parse_args()
    tag=datetime.now().strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:8]
    root=REPO/'_output/windows-lite'/('appcontainer-'+tag);root.mkdir(parents=True,exist_ok=False)
    build_dir=root/'build';build_dir.mkdir();exe=build(build_dir)
    plan={'root':str(root),'sourceSha256':hashlib.sha256((HERE/'probe.c').read_bytes()).hexdigest(),'binarySha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'scope':'Synthetic native executable only; no real applications, network capabilities, or loopback exemption.'}
    (root/'plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
    print(json.dumps({'stage':'built','root':str(root)},ensure_ascii=False),flush=True)
    if args.build_only:return
    profile='Cage.Feasibility.'+uuid.uuid4().hex
    (root/'profile-intent.json').write_text(json.dumps({'name':profile,'ownedByThisProbe':True}),encoding='utf-8')
    result=subprocess.run([str(exe),'--host',str(root),profile,uuid.uuid4().hex],capture_output=True,timeout=75,creationflags=NO_WINDOW)
    (root/'host.log').write_bytes(result.stdout+b'\n'+result.stderr)
    outputs={}
    for role in ('parent','child'):
        for round in ('1','2'):
            file=root/'data'/(role+'-'+round+'.json')
            if file.is_file():outputs[file.stem]=json.loads(file.read_text(encoding='utf-8'))
    host=root/'host-private'
    report={**plan,'exitCode':result.returncode,'results':outputs,'passed':result.returncode==0 and len(outputs)==4 and all(x['passed'] for x in outputs.values()),'hostUnchanged':(host/'host-sentinel.txt').is_file() and (host/'host-sentinel.txt').read_text()=='synthetic host-only marker' and not (host/'must-not-create.txt').exists(),'dataPreserved':True}
    (root/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(result.stdout.decode('utf-8','replace'),end='')
    print(result.stderr.decode('utf-8','replace'),end='')
    print(json.dumps({'root':str(root),'passed':report['passed'],'exitCode':result.returncode,'hostUnchanged':report['hostUnchanged']},ensure_ascii=False),flush=True)
    if not report['passed']:raise SystemExit(1)

if __name__=='__main__':main()
