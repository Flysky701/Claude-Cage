[CmdletBinding()]
param(
    [ValidateSet('PowerShell','ClaudeCode','Node','Git')][string[]]$App=@('PowerShell','ClaudeCode','Node','Git'),
    [string]$ClaudePath=(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local/bin/claude.exe'),
    [string]$NodePath='D:\DevTools\node-v24.21.0-win-x64\node.exe',
    [string]$GitDirectory='D:\DevTools\Git\mingw64\bin',
    [string]$RunDirectory,
    [switch]$PrepareOnly,
    [switch]$ClaudeOfflineGateway,
    [switch]$TemporaryHostRoot,
    [switch]$NodeDefaultEntry
)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build=Join-Path $repo 'tmp/windows-appcontainer'
if($TemporaryHostRoot){
    # A location comparison uses only a fresh user-temp root. Nothing is moved,
    # and neither existing ancestors nor installed programs receive new ACLs.
    $hostTemp=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Temp'
    $build=Join-Path $hostTemp ('CageTerminalApps-'+[guid]::NewGuid().ToString('N'))
}
$probe=Join-Path $build 'TerminalAppsProbe.exe'
New-Item -ItemType Directory -Path $build -Force|Out-Null
$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$sources=@('BoundaryProbe.cs','BoundaryNetwork.cs','BoundaryTerminal.cs','BoundaryTerminalRpc.cs','TerminalAppsProbe.cs')|ForEach-Object{Join-Path $PSScriptRoot $_}
& $compiler /nologo /target:exe /main:TerminalAppsEntry /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll "/out:$probe" @sources
if($LASTEXITCODE -ne 0){throw 'TerminalAppsProbe compilation failed.'}
$go=Join-Path $repo '_output/issue-fixes-tools/go/bin/go.exe'
if(-not(Test-Path -LiteralPath $go -PathType Leaf)){$go=(Get-Command go.exe -ErrorAction Stop).Source}
$oldCache=$env:GOCACHE;$oldProxy=$env:GOPROXY;$oldDB=$env:GOSUMDB;$oldToolchain=$env:GOTOOLCHAIN
try{
    $env:GOCACHE=Join-Path $repo 'tmp/windows-appcontainer/go-cache';$env:GOPROXY='off';$env:GOSUMDB='off';$env:GOTOOLCHAIN='local'
    foreach($name in @('CompatibilityHelper','TerminalWorker','TerminalAppsWorker')){
        & $go build -buildvcs=false -o (Join-Path $build ($name+'.exe')) (Join-Path $PSScriptRoot ($name+'.go'))
        if($LASTEXITCODE -ne 0){throw ('Failed to compile '+$name)}
    }
}finally{$env:GOCACHE=$oldCache;$env:GOPROXY=$oldProxy;$env:GOSUMDB=$oldDB;$env:GOTOOLCHAIN=$oldToolchain}
if(-not $RunDirectory){$RunDirectory=Join-Path $build ('terminal-apps-'+[guid]::NewGuid().ToString('N').Substring(0,12))}
$run=[IO.Path]::GetFullPath($RunDirectory)
if(-not $run.StartsWith($build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'RunDirectory must be below the selected new launcher build directory.'}
if(Test-Path -LiteralPath $run){throw 'Choose a new RunDirectory to preserve previous evidence.'}
New-Item -ItemType Directory -Path $run|Out-Null
$utf8=[Text.UTF8Encoding]::new($false)
$results=[Collections.Generic.List[object]]::new()
function Copy-Program([string]$Source,[string]$Destination){
    $entry=Get-Item -LiteralPath $Source
    if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Program staging does not follow redirected files.'}
    Copy-Item -LiteralPath $Source -Destination $Destination
}
foreach($name in $App){
    $fixture=Join-Path $run $name
    foreach($part in @('tools','work','out','private')){New-Item -ItemType Directory -Path (Join-Path $fixture $part) -Force|Out-Null}
    $toolsDir=Join-Path $fixture 'tools';$work=Join-Path $fixture 'work'
    foreach($helper in @('CompatibilityHelper.exe','TerminalWorker.exe','TerminalAppsWorker.exe')){Copy-Program (Join-Path $build $helper) (Join-Path $toolsDir $helper)}
    switch($name){
        'ClaudeCode'{
            Copy-Program $ClaudePath (Join-Path $toolsDir 'claude.exe')
            New-Item -ItemType Directory -Path (Join-Path $work 'claude-config')|Out-Null
            if($ClaudeOfflineGateway){
                # Documented gateway onboarding avoids Anthropic first-run
                # connectivity preflight. This reserved placeholder has no
                # service or credentials; the verifier never selects login.
                [IO.File]::WriteAllText((Join-Path $work 'claude-config/settings.json'),'{"forceLoginMethod":"gateway","forceLoginGatewayUrl":"https://cage-fixture.invalid"}',$utf8)
            }
        }
        'Node'{
            Copy-Program $NodePath (Join-Path $toolsDir 'node.exe')
            if($NodeDefaultEntry){[IO.File]::WriteAllText((Join-Path $work 'node-default-entry.fixture'),'use default file entry',$utf8)}
            $project=Join-Path $work 'node-project';New-Item -ItemType Directory -Path $project|Out-Null
            [IO.File]::WriteAllText((Join-Path $project 'lib.cjs'),"module.exports = (a,b) => a+b;`n",$utf8)
            $script=@'
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const add=require('./lib.cjs');assert.equal(add(2,3),5);
const file=path.join(__dirname,'roundtrip.txt');fs.writeFileSync(file,'开发终端 UTF-8\n');assert.equal(fs.readFileSync(file,'utf8'),'开发终端 UTF-8\n');
const helper=path.join(process.argv[2],'CompatibilityHelper.exe');
const result=cp.spawnSync(helper,['token','ac'],{stdio:'inherit'});if(result.error)throw result.error;assert.equal(result.status,0);
console.log('CAGE_NODE_LOCAL_PASS');
'@
            [IO.File]::WriteAllText((Join-Path $project 'main.cjs'),$script,$utf8)
        }
        'Git'{
            $dest=Join-Path $toolsDir 'git';New-Item -ItemType Directory -Path $dest|Out-Null
            # Native git plus its adjacent runtime DLLs; no etc, gitconfig,
            # credential files, hooks, user profiles or portable tmp directory.
            foreach($entry in Get-ChildItem -LiteralPath $GitDirectory -File | Where-Object{$_.Name -eq 'git.exe' -or $_.Extension -eq '.dll'}){Copy-Program $entry.FullName (Join-Path $dest $entry.Name)}
            $project=Join-Path $work 'git-project';New-Item -ItemType Directory -Path $project|Out-Null
            New-Item -ItemType Directory -Path (Join-Path $work 'empty-templates')|Out-Null
            [IO.File]::WriteAllText((Join-Path $work 'empty.gitconfig'),'',$utf8)
            [IO.File]::WriteAllText((Join-Path $project 'sample.txt'),"local fixture`n",$utf8)
        }
    }
    $shell=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $toolsLiteral="'"+$toolsDir.Replace("'","''")+"'"
    $bootstrap='$ErrorActionPreference=''Stop''; New-PSDrive -Name Cage -PSProvider FileSystem -Root $env:HOME | Out-Null; New-PSDrive -Name CageTools -PSProvider FileSystem -Root '+$toolsLiteral+' | Out-Null; Set-Location Cage:\'
    $prepared=[ordered]@{
        app=$name;fixture=$fixture;launcher=$probe
        verificationArguments=@('app-suite',$name,$fixture)
        terminalArguments=@('terminal-rpc','ac',$fixture,$shell,'-NoLogo','-NoProfile','-NoExit','-Command',$bootstrap)
        openMessage=[ordered]@{action='open';workspace='home';shell='powershell';cols=120;rows=35}
        note='Use terminalArguments with startWindowsAppContainerTerminal so the host owns profile cleanup. Cage: is the writable work tree; CageTools: is read/execute. No host credentials are inherited.'
    }
    [IO.File]::WriteAllText((Join-Path $fixture 'prepared.json'),($prepared|ConvertTo-Json -Depth 8),$utf8)
    if($PrepareOnly){$results.Add($prepared);continue}
    Write-Output ('Testing '+$name+' local terminal')|Out-Host
    $raw=@(& $probe app-suite $name $fixture 2>&1 | ForEach-Object{$_.ToString()}) -join "`n"
    try{$result=$raw|ConvertFrom-Json}catch{throw ('Launcher result invalid: '+$raw)}
    $results.Add($result);Write-Output $raw
}
$report=[ordered]@{schema=1;mode='ac';network='zero capabilities; no login or model request';preparedOnly=[bool]$PrepareOnly;temporaryHostRoot=[bool]$TemporaryHostRoot;nodeDefaultEntry=[bool]$NodeDefaultEntry;results=@($results.ToArray())}
[IO.File]::WriteAllText((Join-Path $run 'results.json'),($report|ConvertTo-Json -Depth 12),$utf8)
Write-Output ('Saved '+(Join-Path $run 'results.json'))
if(-not $PrepareOnly -and @($results|Where-Object{-not $_.passed}).Count){exit 1}
