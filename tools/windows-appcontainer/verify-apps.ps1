[CmdletBinding()]
param(
    [ValidateSet('ClaudeCode','Node','Edge','VSCode')][string[]]$App = @('ClaudeCode','Node','Edge','VSCode'),
    [ValidateSet('ac','lpac','both')][string]$Mode = 'both',
    [string]$ClaudePath = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local/bin/claude.exe'),
    [string]$NodePath = 'D:\DevTools\node-v24.21.0-win-x64\node.exe',
    [string]$EdgePath = (Join-Path ${env:ProgramFiles(x86)} 'Microsoft/Edge/Application/msedge.exe'),
    [string]$CodeDirectory = (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'AppData/Local/Programs/Microsoft VS Code'),
    [string]$RunDirectory,
    [switch]$TryEditor,
    [switch]$PreserveSymlinks
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build = Join-Path $repo 'tmp/windows-appcontainer'
$launcher = Join-Path $build 'BoundaryProbe.exe'
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw 'Build BoundaryProbe with verify-boundary.ps1 -BuildOnly first.' }
if (-not $RunDirectory) { $RunDirectory = Join-Path $build ('apps-' + [guid]::NewGuid().ToString('N').Substring(0,12)) }
$run = [IO.Path]::GetFullPath($RunDirectory)
if (-not $run.StartsWith($build + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'RunDirectory must be below tmp/windows-appcontainer.' }
if (Test-Path -LiteralPath $run) { throw 'RunDirectory already exists; use a new directory to preserve previous results.' }
New-Item -ItemType Directory -Path $run | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
$modes = if ($Mode -eq 'both') { @('ac','lpac') } else { @($Mode) }
$results = [Collections.Generic.List[object]]::new()

# Native fixture helper avoids requiring the CLR in the LPAC candidate.
$helperExe = Join-Path $run 'CompatibilityHelper.exe'
$go = Join-Path $repo '_output/issue-fixes-tools/go/bin/go.exe'
if (-not (Test-Path -LiteralPath $go -PathType Leaf)) { $go=(Get-Command go -ErrorAction Stop).Source }
$oldCache=$env:GOCACHE;$oldProxy=$env:GOPROXY;$oldDB=$env:GOSUMDB;$oldToolchain=$env:GOTOOLCHAIN
try {
    $env:GOCACHE=Join-Path $build 'go-cache';$env:GOPROXY='off';$env:GOSUMDB='off';$env:GOTOOLCHAIN='local'
    & $go build -buildvcs=false -o $helperExe (Join-Path $PSScriptRoot 'CompatibilityHelper.go')
    if($LASTEXITCODE -ne 0){throw 'Native compatibility helper compilation failed.'}
} finally { $env:GOCACHE=$oldCache;$env:GOPROXY=$oldProxy;$env:GOSUMDB=$oldDB;$env:GOTOOLCHAIN=$oldToolchain }
function New-Fixture([string]$Name) {
    $fixture = Join-Path $run $Name
    foreach($part in @('tools','work','out','private')) { New-Item -ItemType Directory -Path (Join-Path $fixture $part) -Force | Out-Null }
    [IO.File]::WriteAllText((Join-Path $fixture 'private/host-fixture.txt'),'HOST_FIXTURE_NOT_A_REAL_SECRET',$utf8)
    return $fixture
}
function Copy-Program([string]$Source,[string]$Destination) {
    $item=Get-Item -LiteralPath $Source
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Use an ordinary application file or installation tree, not a redirected path.' }
    if($item.PSIsContainer -and @(Get-ChildItem -LiteralPath $Source -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Application installation tree contains a redirected path; preserve it and choose a plain staging source.' }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
}
function Copy-CodeInstallation([string]$Source,[string]$Destination) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
    foreach($entry in Get-ChildItem -LiteralPath $Source -Force) {
        # Portable user data is adjacent to the program. Built-in extensions
        # under resources/app remain program files and must stay available.
        if($entry.Name -in @('data','User','profiles','user-data','extensions','.vscode') -or $entry.Name -like 'unins*') { continue }
        Copy-Program $entry.FullName (Join-Path $Destination $entry.Name)
    }
}
function Invoke-Candidate([string]$Name,[string]$Candidate,[string]$Fixture,[string]$Executable,[string[]]$Arguments,[int]$Timeout,[string]$Scope) {
    $launchArgs=@('launch',$Candidate,$Fixture,$Executable,[string]$Timeout)+$Arguments
    Write-Output ("Testing {0} {1} ({2})" -f $Name,$Candidate,$Scope) | Out-Host
    $nativeText=@(& $launcher @launchArgs 2>&1 | ForEach-Object { $_.ToString() }) -join "`n"
    $launcherExit=$LASTEXITCODE
    $receiptPath=Join-Path $Fixture 'launch.json'
    $receipt=if(Test-Path -LiteralPath $receiptPath){Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json}else{$null}
    $stdoutPath=Join-Path $Fixture 'out/launch/stdout.txt'
    $stderrPath=Join-Path $Fixture 'out/launch/stderr.txt'
    $stdout=if(Test-Path -LiteralPath $stdoutPath){[IO.File]::ReadAllText($stdoutPath)}else{''}
    $stderr=if(Test-Path -LiteralPath $stderrPath){[IO.File]::ReadAllText($stderrPath)}else{''}
    $archive=Join-Path $run ('results/'+$Name+'-'+$Candidate)
    New-Item -ItemType Directory -Path $archive -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $archive 'launcher.txt'),$nativeText,$utf8)
    [IO.File]::WriteAllText((Join-Path $archive 'stdout.txt'),$stdout,$utf8)
    [IO.File]::WriteAllText((Join-Path $archive 'stderr.txt'),$stderr,$utf8)
    if($receipt){[IO.File]::WriteAllText((Join-Path $archive 'launch.json'),($receipt|ConvertTo-Json -Depth 8),$utf8)}
    return [ordered]@{app=$Name;mode=$Candidate;scope=$Scope;launcherExit=$launcherExit;receipt=$receipt;stdout=$stdout;stderr=$stderr;artifactDirectory=$archive;passed=$false}
}
function Complete-Result($Result,[bool]$Observed) {
    $r=$Result.receipt
    $Result.passed=[bool]($Observed -and $r -and $r.tokenVerified -and $r.isAppContainer -and $r.capabilityCount -eq 0 -and $r.isLPAC -eq ($Result.mode -eq 'lpac') -and $r.exitCode -eq 0 -and -not $r.timedOut -and $r.profileDeleteResult -eq 0 -and -not $r.error)
    $results.Add($Result)
    [IO.File]::WriteAllText((Join-Path $run 'results.json'),(@{schema=1;network='zero capabilities; no live API or login';results=@($results.ToArray())}|ConvertTo-Json -Depth 12),$utf8)
    Write-Output ("{0} {1}: {2}" -f $Result.app,$Result.mode,$(if($Result.passed){'PASS'}else{'NOT PASSED'})) | Out-Host
}

foreach($name in $App) {
    foreach($candidate in $modes) {
        $fixture=New-Fixture ($name+'-'+$candidate)
        $toolsDir=Join-Path $fixture 'tools';$work=Join-Path $fixture 'work'
        try {
            switch($name) {
                'ClaudeCode' {
                    Copy-Program $ClaudePath (Join-Path $toolsDir 'claude.exe')
                    $r=Invoke-Candidate $name $candidate $fixture (Join-Path $toolsDir 'claude.exe') @('--version') 25 'version only; no login, model request, terminal interaction or tools'
                    Complete-Result $r ($r.stdout -match '\d+\.\d+\.\d+.*Claude Code')
                }
                'Node' {
                    Copy-Program $NodePath (Join-Path $toolsDir 'node.exe')
                    Copy-Program $helperExe (Join-Path $toolsDir 'CompatibilityHelper.exe')
                    $nodeScript=@'
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const [tools,mode]=process.argv.slice(-2);if(!['ac','lpac'].includes(mode))throw Error('invalid mode');
const fixture=path.dirname(tools),work=path.join(fixture,'work');
const helper=path.join(tools,'CompatibilityHelper.exe');
let sequence=0;
function run(file,args,options={}){
  const name=path.join(work,'child-'+(++sequence)),out=fs.openSync(name+'.out','w'),err=fs.openSync(name+'.err','w');
  let result;try{result=cp.spawnSync(file,args,{timeout:8000,windowsHide:true,stdio:[0,out,err],...options});}finally{fs.closeSync(out);fs.closeSync(err);}
  if(result.error)throw result.error;if(result.status!==0)throw Error('child failed '+result.status+' '+fs.readFileSync(name+'.err','utf8'));
  return fs.readFileSync(name+'.out','utf8').trim();
}
console.log('CAGE_NODE_STAGE: fixture entry started');
const ownChild=run(helper,['token',mode]);
console.log('CAGE_NODE_STAGE: direct child token verified');
// This command consists entirely of fixed fixture names and an enumerated mode.
const cmdChild=run(process.env.COMSPEC,['/d','/s','/c','CompatibilityHelper.exe token '+mode],{cwd:tools});
console.log('CAGE_NODE_STAGE: cmd child token verified');
if(ownChild!==cmdChild)throw Error('cmd child token differs');
let privateDenied=false,toolsDenied=false;
try{fs.readFileSync(path.join(fixture,'private','host-fixture.txt'));}catch(e){privateDenied=['EACCES','EPERM'].includes(e.code);}
try{fs.writeFileSync(path.join(tools,'unexpected-write.txt'),'bad');}catch(e){toolsDenied=['EACCES','EPERM'].includes(e.code);}
fs.writeFileSync(path.join(work,'node-fixture.txt'),'CAGE_NODE_LOCAL_FILE');
const fileRoundTrip=fs.readFileSync(path.join(work,'node-fixture.txt'),'utf8')==='CAGE_NODE_LOCAL_FILE';
if(!privateDenied||!toolsDenied||!fileRoundTrip)throw Error('file boundary check failed');
console.log(JSON.stringify({marker:'CAGE_NODE_COMPAT_PASS',node:process.version,cmdChildToken:cmdChild,privateDenied,toolsDenied,fileRoundTrip}));
'@
                    [IO.File]::WriteAllText((Join-Path $toolsDir 'node-check.cjs'),$nodeScript,$utf8)
                    # -e avoids granting directory-list access on D:\ merely
                    # for Node's script-entry realpath traversal. Module-loading
                    # compatibility remains a separate, unverified concern.
                    if($PreserveSymlinks){
                        $nodeArgs=@('--preserve-symlinks-main','--preserve-symlinks',(Join-Path $toolsDir 'node-check.cjs'),$toolsDir,$candidate)
                        $r=Invoke-Candidate 'Node-file-entry-preserve-symlinks' $candidate $fixture (Join-Path $toolsDir 'node.exe') $nodeArgs 35 'file-entry fixture with preserve-symlinks flags; no extra filesystem permissions'
                    }else{
                        $r=Invoke-Candidate $name $candidate $fixture (Join-Path $toolsDir 'node.exe') @('-e',$nodeScript,$toolsDir,$candidate) 35 'Node -e local file operations and cmd child token; file-entry/module loading not certified; no network'
                    }
                    Complete-Result $r ($r.stdout -match 'CAGE_NODE_COMPAT_PASS')
                }
                'Edge' {
                    [IO.File]::WriteAllText((Join-Path $work 'page.html'),'<!doctype html><title>Cage isolated fixture</title><body><script>document.body.textContent="CAGE_EDGE_DOM_PASS";</script></body>',$utf8)
                    $url=([uri](Join-Path $work 'page.html')).AbsoluteUri
                    $edgeArgs=@('--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-background-networking','--disable-component-update','--disable-sync','--disable-extensions','--disable-quic',('--user-data-dir='+ (Join-Path $work 'edge-profile')),'--dump-dom','--timeout=10000',$url)
                    $r=Invoke-Candidate $name $candidate $fixture $EdgePath $edgeArgs 35 'headless local HTML JavaScript DOM; default internal sandbox; no host profile'
                    Complete-Result $r ($r.stdout -match '<body>CAGE_EDGE_DOM_PASS</body>')
                }
                'VSCode' {
                    $codeStage=Join-Path $toolsDir 'vscode'
                    # Installation files only: no user's profiles or extension directory.
                    Copy-CodeInstallation $CodeDirectory $codeStage
                    Copy-Program $helperExe (Join-Path $toolsDir 'CompatibilityHelper.exe')
                    $cli=@(Get-ChildItem -LiteralPath $codeStage -Filter 'cli.js' -File -Recurse | Where-Object FullName -Match '[\\/]resources[\\/]app[\\/]out[\\/]cli\.js$')
                    if($cli.Count -ne 1){throw 'Expected exactly one installed VS Code CLI entry.'}
                    $codeExe=Join-Path $codeStage 'Code.exe'
                    $codeArgs=@('code-version',$candidate,$codeExe,$cli[0].FullName,(Join-Path $work 'code-profile'),(Join-Path $work 'code-extensions'))
                    if($PreserveSymlinks){$codeArgs+='preserve-symlinks'}
                    $caseName=if($PreserveSymlinks){'VSCode-preserve-symlinks'}else{$name}
                    $r=Invoke-Candidate $caseName $candidate $fixture (Join-Path $toolsDir 'CompatibilityHelper.exe') $codeArgs 35 'Electron CLI --version with child-token check; optional explicit NODE_OPTIONS preserve-symlinks comparison; no editor UI claim'
                    Complete-Result $r ($r.stdout -match '(?m)^\d+\.\d+\.\d+\s*$' -and $r.stdout -match 'CAGE_TOKEN_VERIFIED:')
                    if($TryEditor -and $r.passed){
                        [IO.File]::WriteAllText((Join-Path $work 'scratch.txt'),'CAGE_EDITOR_LOCAL_FIXTURE',$utf8)
                        $r=Invoke-Candidate 'VSCode-editor' $candidate $fixture $codeExe @(('--user-data-dir='+(Join-Path $work 'editor-profile')),('--extensions-dir='+(Join-Path $work 'editor-extensions')),'--disable-extensions','--skip-welcome','--skip-release-notes','--new-window','--wait',(Join-Path $work 'scratch.txt')) 15 'editor launch observation only; requires separate visible editing verification'
                        Complete-Result $r $false
                    }
                }
            }
        } catch {
            $failure=[ordered]@{app=$name;mode=$candidate;scope='fixture preparation or launcher invocation';passed=$false;error=$_.Exception.Message;fixture=$fixture}
            $results.Add($failure)
            [IO.File]::WriteAllText((Join-Path $run 'results.json'),(@{schema=1;network='zero capabilities; no live API or login';results=@($results.ToArray())}|ConvertTo-Json -Depth 12),$utf8)
            Write-Output ("{0} {1}: ERROR {2}" -f $name,$candidate,$_.Exception.Message) | Out-Host
        }
    }
}
Write-Output ('Results: '+(Join-Path $run 'results.json'))
if(@($results|Where-Object { -not $_.passed }).Count){exit 1}
