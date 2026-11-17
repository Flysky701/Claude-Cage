[CmdletBinding()]
param(
    [ValidateSet('ac','lpac','both')][string]$Mode='both',
    [string]$GoPath,
    [switch]$BuildOnly
)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build=Join-Path $repo 'tmp/windows-appcontainer'
$launcher=Join-Path $build 'BoundaryProbe.exe'
if(-not (Test-Path -LiteralPath $launcher -PathType Leaf)){throw 'Build BoundaryProbe with the terminal partial included first.'}
if(-not $GoPath){
    $GoPath=Join-Path $repo '_output/issue-fixes-tools/go/bin/go.exe'
    if(-not (Test-Path -LiteralPath $GoPath -PathType Leaf)){$GoPath=(Get-Command go.exe -ErrorAction Stop).Source}
}
$oldCache=$env:GOCACHE;$oldProxy=$env:GOPROXY;$oldDB=$env:GOSUMDB;$oldToolchain=$env:GOTOOLCHAIN
try {
    $env:GOCACHE=Join-Path $build 'go-cache';$env:GOPROXY='off';$env:GOSUMDB='off';$env:GOTOOLCHAIN='local'
    foreach($name in @('CompatibilityHelper','TerminalWorker')){
        & $GoPath build -buildvcs=false -o (Join-Path $build ($name+'.exe')) (Join-Path $PSScriptRoot ($name+'.go'))
        if($LASTEXITCODE -ne 0){throw ('Failed to compile '+$name)}
    }
}finally{$env:GOCACHE=$oldCache;$env:GOPROXY=$oldProxy;$env:GOSUMDB=$oldDB;$env:GOTOOLCHAIN=$oldToolchain}
if($BuildOnly){Write-Output 'Native terminal helpers built.';exit 0}
$modes=if($Mode -eq 'both'){@('ac','lpac')}else{@($Mode)}
$results=[Collections.Generic.List[object]]::new()
foreach($candidate in $modes){
    $native=@(& $launcher terminal-suite $candidate 2>&1 | ForEach-Object{$_.ToString()}) -join "`n"
    try{$result=$native|ConvertFrom-Json}catch{throw ('Terminal launcher did not return a result: '+$native)}
    $results.Add($result)
    Write-Output $native
}
$report=[ordered]@{schema=1;scope='offline local terminal candidate; no backend switch';network='zero capabilities; no network calls';results=@($results.ToArray())}
$output=Join-Path $build ('terminal-verification-'+[guid]::NewGuid().ToString('N')+'.json')
[IO.File]::WriteAllText($output,($report|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
Write-Output ('Saved '+$output)
if(@($results | Where-Object{-not $_.passed}).Count){exit 1}
