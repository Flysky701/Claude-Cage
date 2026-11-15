import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const [sdkRoot, root] = process.argv.slice(2);
const {probe, spawnWithPty} = await import(pathToFileURL(path.join(sdkRoot,'dist/v1/index.js')));
const data = path.join(root,'data');
const binary = path.join(root,'bin','CageMxcTerminalProbe.exe');
const reportPath = path.join(data,'terminal-child.json');
const request = {
  containment: {type:'processcontainer'},
  command: `"${binary}" "${reportPath}"`,
  filesystem: {readonlyPaths:[path.dirname(binary)], readwritePaths:[data]},
  network: {egress:{default:'deny'},ingress:{default:'deny',hostLoopback:'deny'}},
  workingDirectory:data,
  environment:{SystemRoot:process.env.SystemRoot, WINDIR:process.env.WINDIR,
    TEMP:data,TMP:data,USERPROFILE:data,LOCALAPPDATA:data,APPDATA:data},
  inheritDefaultEnvironment:false,
  timeoutMs:20000,
};
fs.writeFileSync(path.join(root,'terminal-request.json'),JSON.stringify(request,null,2));
const capability=await probe(request);
fs.writeFileSync(path.join(root,'terminal-probe.json'),JSON.stringify(capability,null,2));
if (capability.tier!=='base-container'||capability.needsDaclAugmentation||capability.error) {
  throw new Error(`Native containment not available: ${JSON.stringify(capability)}`);
}
let terminal, output='', sent=false, result;
const input='synthetic-'+Date.now().toString(16);
try {
  terminal=await spawnWithPty(request,{size:{columns:100,rows:30}});
  // Claim stdin before wait(): the SDK closes an untaken stream at wait time.
  const terminalInput=terminal.input;
  terminal.output.on('data', chunk=>{
    output+=chunk.toString();
    if (!sent && output.includes('CAGE_MXC_TERMINAL_READY')) {
      sent=true;
      terminal.resize({columns:120,rows:40});
      setTimeout(()=>terminalInput.write(input+'\r'),250);
    }
  });
  const deadline=setTimeout(()=>terminal.kill(),25000);
  try { result=await terminal.wait(); } finally {clearTimeout(deadline);}
} finally {
  if(terminal) terminal.dispose();
  fs.writeFileSync(path.join(root,'terminal-output.log'),output);
}
const child=fs.existsSync(reportPath)?JSON.parse(fs.readFileSync(reportPath,'utf8')):null;
const passed=result?.exitCode===0 && child?.appContainer===true && child?.received===input &&
  child?.initialColumns===100 && child?.initialRows===30 && child?.columns===120 && child?.rows===40 &&
  output.includes('CAGE_MXC_TERMINAL_READ_AND_RESIZE_COMPLETE');
const report={passed,result,child,requestProbe:capability.tier,realApplicationsLaunched:false};
fs.writeFileSync(path.join(root,'terminal-report.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify(report));
// Koffi's loaded native runtime keeps background handles alive after disposal.
// The synthetic workload has finished; no persistent session belongs to it.
process.exit(passed?0:1);
