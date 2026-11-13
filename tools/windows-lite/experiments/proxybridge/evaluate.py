"""Bounded ProxyBridge 4.3.0 evaluation. Only the two test EXEs and 1.1.1.1:443."""
import argparse
import collections
import contextlib
import ctypes
import hashlib
import http.client
import json
import os
from pathlib import Path
import secrets
import select
import socket
import socketserver
import ssl
import subprocess
import sys
import threading
import time
import uuid

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT))
import shell as lite

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,v):
    t=p.with_suffix('.new');t.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8');t.replace(p)
def wait(p,timeout=22):
    end=time.monotonic()+timeout
    while not p.is_file():
        if time.monotonic()>end:raise TimeoutError("missing "+p.name)
        time.sleep(.1)
    return read(p)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()

class Hop(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            with socket.create_connection(self.server.fixed,timeout=8) as upstream:
                with self.server.lock:self.server.sessions+=1
                ends=[self.request,upstream]
                while not self.server.ending.is_set():
                    for peer in select.select(ends,[],[],.2)[0]:
                        data=peer.recv(32768)
                        if not data:return
                        ends[1-ends.index(peer)].sendall(data)
                        with self.server.lock:self.server.total+=len(data)
        except OSError:pass

class Workload:
    def __init__(self,exe,out,box=None):
        self.out=out;out.mkdir(parents=True,exist_ok=False)
        cmd=([box.start,'/box:'+box.name,'/silent','/wait'] if box else [])+[str(exe),str(out)]
        self.proc=subprocess.Popen(cmd,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        self.seq=collections.Counter()
        self.ids={r:wait(out/(r+'.pid')) for r in ('parent','child')}
        if box and not set(self.ids.values()).issubset(set(box.pids())):raise RuntimeError('box membership mismatch')
    def command(self,role,command):
        index=self.seq[role];self.seq[role]+=1
        base=self.out/(role+'-'+str(index))
        tmp=base.with_suffix('.tmpcmd');tmp.write_text(command,encoding='ascii');tmp.replace(base.with_suffix('.cmd'))
        return wait(base.with_suffix('.json'),35)
    def close(self):
        (self.out/'done').touch()
        try:self.proc.wait(timeout=18)
        except subprocess.TimeoutExpired:raise RuntimeError('workload failed to exit')

def independent_control():
    try:
        with socket.create_connection(('1.1.1.1',443),timeout=6) as raw:
            with ssl.create_default_context().wrap_socket(raw,server_hostname='1.1.1.1') as tls:
                tls.sendall(b'GET /cdn-cgi/trace HTTP/1.1\r\nHost: 1.1.1.1\r\nConnection: close\r\n\r\n')
                resp=http.client.HTTPResponse(tls);resp.begin()
                addr=next((ln[3:] for ln in resp.read(8192).decode().splitlines() if ln.startswith('ip=')),None)
                return dict(status=resp.status,exit=addr)
    except (OSError,ValueError,http.client.HTTPException) as e:return {'error':str(e)}

def memory(groups):
    ids=set(i for vals in groups.values() for i in vals)
    if not ids:return {}
    cmd='@(Get-Process -Id '+','.join(str(i) for i in ids)+' -ErrorAction SilentlyContinue|Select-Object Id,ProcessName,PrivateMemorySize64,WorkingSet64)|ConvertTo-Json -Compress'
    rows=json.loads(subprocess.check_output(['powershell','-NoProfile','-Command',cmd],timeout=15))
    return {k:[row for row in rows if row['Id'] in vals] for k,vals in groups.items()}

def run(work, control_only=False, allow_control=False):
    work=work.resolve();session='pb-'+uuid.uuid4().hex[:12];ctl=work/session;ctl.mkdir()
    result={'session':session,'release':'v4.3.0_Windows','conditions':[],'memory':{},'controls':{}}
    result['controlOnly']=control_only
    save=lambda:write(work/('narrow-allow.json' if allow_control else 'negative-controls.json' if control_only else 'results.json'),result)
    parent=work/'CagePBCheckParent.exe';child=work/'CagePBCheckChild.exe'
    result['testFiles']={p.name:digest(p) for p in (parent,child)}
    private=ctl/'private';private.mkdir()
    shared=ctl/'output';shared.mkdir()
    sbdir=Path(os.environ['ProgramFiles'])/'Sandboxie-Plus'
    box=lite.Sandbox(sbdir,'CageLite_'+session[3:])
    source=Path.home()/'.claude-cage'/'config.json'
    upstream,doh=lite.validate_endpoints(lite.read_json(source))
    if upstream.hostname not in ('127.0.0.1','::1'):raise RuntimeError('expected the existing local Cage endpoint')
    core=Path(lite.read_json(source.parent/'proxy'/'managed-process.json')['executable'])
    result['wfpGlobal']=box.settings('query','GlobalSettings','NetworkEnableWFP')
    controller=None
    def stop_engine():
        (ctl/'stop').touch()
        if controller is not None:
            record=wait(ctl/'engine-final.json',45);result['engineFinal']=record
            if not record.get('stageRemoved') or record.get('remainingDrivers'):raise RuntimeError('engine cleanup needs inspection')
    try:
        with contextlib.ExitStack() as st:
            hop=st.enter_context(socketserver.ThreadingTCPServer(('127.0.0.1',0),Hop));hop.daemon_threads=True;hop.fixed=(upstream.hostname,upstream.port)
            hop.lock=threading.Lock();hop.ending=threading.Event();hop.sessions=hop.total=0
            threading.Thread(target=hop.serve_forever,daemon=True).start();st.callback(hop.shutdown);st.callback(hop.ending.set)
            auth=upstream.netloc.rpartition('@')[0]
            watched=upstream._replace(netloc=(auth+'@' if auth else '')+'127.0.0.1:'+str(hop.server_address[1]))
            route,relay=st.enter_context(lite.data_gateway(core,private,watched,doh))
            broker=st.enter_context(lite.DNSBroker(route,secrets.token_hex(32)))
            threading.Thread(target=broker.serve_forever,daemon=True).start();st.callback(broker.shutdown)
            fixed=st.enter_context(lite.FixedService(box,broker,('1.1.1.1',443,0)))
            threading.Thread(target=fixed.serve_forever,daemon=True).start();st.callback(fixed.shutdown)
            bound=fixed.server_address[1]
            st.enter_context(box.configure(parent,[child],private,ctl/'box',shared,source,route,broker,{'trace':bound}))
            if allow_control:
                for file in (parent,child):
                    box.settings('append',box.name,'NetworkAccess',file.name+',Allow;Address=1.1.1.1;Port=443;Protocol=TCP')
            outside=Workload(parent,ctl/'outside');st.callback(outside.close)
            inside=Workload(parent,shared/'strict',box);st.callback(inside.close)
            def test(label,who,role,cmd):
                n,b=hop.sessions,hop.total
                row=who.command(role,cmd)
                result['conditions'].append(dict(phase=label,side='outside' if who is outside else 'inside',role=role,
                                                 downstream=row,upstreamSessions=hop.sessions-n,upstreamBytes=hop.total-b))
                save()
            def phase(label,external=True,cmd='original 443'):
                print(label,flush=True)
                for role in ('parent','child'):
                    test(label,inside,role,cmd)
                    if external:test(label,outside,role,'original 443')
            def dns(label,positive):
                for who in (inside,outside):
                    for role in ('parent','child'):
                        test(label,who,role,'dns '+positive)
                        if who is inside:test(label,who,role,'dns pb'+uuid.uuid4().hex[:14]+'.cage.test.')
            def snap(label):
                b=set(box.pids())
                result['memory'][label]=memory({'launcher':[os.getpid()],'mihomo':[relay.pid],'boxed':list(inside.ids.values()),
                    'outside':list(outside.ids.values()),'boxHelpers':list(b-set(inside.ids.values()))})
                save()
            if control_only:
                if allow_control:
                    phase('no-engine-original-permitted-relay-alive')
                    test('no-engine-fixed-still-proxied',inside,'parent','mapped '+str(bound))
                else:
                    dns('baseline-dns','example.com.')
                return
            phase('baseline-fixed',cmd='mapped '+str(bound))
            phase('baseline-literal',external=False)
            snap('base')
            # Only disposable session credentials; no persistent profile or global ProxyBridge config.
            cfg=private/'route.json';write(cfg,{'port':route.port,'ticket':route.password})
            st.callback(lambda:cfg.unlink(missing_ok=True))
            elevated=Path(__file__).with_name('engine-test.ps1')
            def quote_ps(v):return "'"+str(v).replace("'","''")+"'"
            psargs='-NoProfile -ExecutionPolicy RemoteSigned -File "'+str(elevated)+'" -Work "'+str(work)+'" -Session '+session
            controller=subprocess.Popen(['powershell','-NoProfile','-Command','Start-Process powershell -Verb RunAs -WindowStyle Hidden -Wait -ArgumentList '+quote_ps(psargs)])
            st.callback(stop_engine)
            end=time.monotonic()+300
            while not (ctl/'engine.json').exists():
                if (ctl/'engine-final.json').is_file():raise RuntimeError(str(read(ctl/'engine-final.json').get('error','engine exited before start')))
                if controller.poll() is not None:raise RuntimeError('elevation/engine bootstrap did not start')
                if time.monotonic()>end:raise RuntimeError('engine startup timed out')
                time.sleep(.2)
            result['engine']=read(ctl/'engine.json');save()
            if not result['engine'].get('started'):raise RuntimeError('official engine failed to stay running')
            phase('engine-strict')
            inside.close()
            box.control('/terminate')
            deadline=time.monotonic()+12
            while box.pids():
                if time.monotonic()>deadline:raise RuntimeError('the first test box process tree did not exit')
                time.sleep(.1)
            # Diagnostic allowance for only the two owned binaries at exactly the one destination.
            # The release launcher never installs these exemptions.
            for file in (parent,child):
                box.settings('append',box.name,'NetworkAccess',file.name+',Allow;Address=1.1.1.1;Port=443;Protocol=TCP')
            inside=Workload(parent,shared/'diagnostic',box);st.callback(inside.close)
            phase('engine-diagnostic')
            dns('dns-online','example.com.')
            (ctl/'sample').touch();snap('withPB')
            result['memory']['engine']=wait(ctl/'engine-mem.json')
            relay.kill();relay.wait()
            phase('mihomo-off');dns('dns-mihomo-off','example.org.')
            result['controls']['mihomo-off']=independent_control();save()
            _,relay=st.enter_context(lite.data_gateway(core,private,watched,doh,reuse_session=route))
            phase('both-restored')
            stop_engine();result['stoppedOnlyEngineWhileMihomoAlive']=relay.poll() is None
            phase('engine-off');dns('dns-engine-off','example.net.')
            result['controls']['engine-off']=independent_control()
            test('engine-off-fixed-gateway-control',inside,'parent','mapped '+str(bound))
            save()
    except BaseException as e:
        result['error']=type(e).__name__+': '+str(e)
        raise
    finally:
        (ctl/'stop').touch()
        (private/'route.json').unlink(missing_ok=True)
        if (ctl/'engine-final.json').exists():result['engineFinal']=read(ctl/'engine-final.json')
        result['boxRemoved']=box.name not in box.settings('query','*')
        save()

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('work',type=Path)
    parser.add_argument('--control-only',action='store_true')
    parser.add_argument('--allow-control-only',action='store_true')
    args=parser.parse_args();run(args.work,args.control_only or args.allow_control_only,args.allow_control_only)
