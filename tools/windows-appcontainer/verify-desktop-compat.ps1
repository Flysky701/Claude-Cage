[CmdletBinding()]
param(
    [ValidateSet('diagnose','station-chain','station-duplicate')][string]$Mode='diagnose',
    [ValidateRange(5,120)][int]$ObservationSeconds=20,
    [string]$SourceDirectory=(Join-Path $PSScriptRoot '../../tmp/windows-appcontainer/desktop-source/extracted/app'),
    [string]$RunDirectory,
    [switch]$BuildOnly
)

# station-chain explicitly invokes a bounded UAC helper; it creates only a new
# random window station and desktop. Diagnose never requests elevation itself.
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build=Join-Path $repo 'tmp/windows-appcontainer'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$binary=Join-Path $build 'DesktopCompatProbe.exe'
$sources=@('BoundaryProbe.cs','BoundaryNetwork.cs','BoundaryTerminal.cs','BoundaryTerminalRpc.cs',
           'DesktopCompatProbe.cs','DesktopCompatWindowStation.cs','DesktopCompatStationBroker.cs') |
    ForEach-Object { Join-Path $PSScriptRoot $_ }
& $compiler /nologo /target:exe /platform:x64 /optimize+ /unsafe /main:DesktopCompatEntry /r:System.Web.Extensions.dll ("/out:$binary") @sources
if($LASTEXITCODE -ne 0){throw 'Desktop diagnostic build failed.'}
if($BuildOnly){Write-Output $binary;return}
if(-not $RunDirectory){$RunDirectory=Join-Path $build ('desktop-compat-'+[guid]::NewGuid().ToString('N'))}
$run=[IO.Path]::GetFullPath($RunDirectory)
if(-not $run.StartsWith($build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'RunDirectory must be a new fixture below tmp/windows-appcontainer.'}
if(Test-Path -LiteralPath $run){throw 'Use a new RunDirectory to preserve earlier results.'}
if($Mode -in @('station-chain','station-duplicate')){
    $action=if($Mode -eq 'station-duplicate'){'--broker-station-duplicate-test'}else{'--broker-station-test'}
    & $binary $action $run
    if($LASTEXITCODE -ne 0){throw 'Station chain did not complete; inspect broker-chain.json and out/station-broker/result.json.'}
    Write-Output ('Retained station-chain evidence: '+$run)
    return
}
$source=[IO.Path]::GetFullPath($SourceDirectory)
if(-not (Test-Path -LiteralPath (Join-Path $source 'Claude.exe') -PathType Leaf)){throw 'Prepare the official Desktop files first.'}
if(@(Get-ChildItem -LiteralPath $source -Recurse -Force | Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}).Count){throw 'Application files must not include redirected paths.'}
New-Item -ItemType Directory -Path (Join-Path $run 'tools') -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $run 'tools/app') -Recurse
& $binary $run (Join-Path $run 'tools/app/Claude.exe') ([string]$ObservationSeconds) `
    ('--user-data-dir='+(Join-Path $run 'work/profile')) '--disable-gpu' '--disable-background-networking' `
    '--disable-component-update' '--disable-sync' '--enable-logging=file' `
    ('--log-file='+(Join-Path $run 'work/electron.log')) '--v=1'
if($LASTEXITCODE -ne 0){throw 'Diagnostic launcher failed; inspect desktop-compat.json.'}
Write-Output ('Retained offline crash/hang evidence: '+$run)
