[CmdletBinding()]
param(
    [string]$RunDirectory,
    [string]$EdgePath = (Join-Path ${env:ProgramFiles(x86)} 'Microsoft/Edge/Application/msedge.exe')
)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build=Join-Path $repo 'tmp/windows-appcontainer'
if(-not $RunDirectory){$RunDirectory=Join-Path $build ('browser-candidate-'+[guid]::NewGuid().ToString('N').Substring(0,12))}
$run=[IO.Path]::GetFullPath($RunDirectory)
if(-not $run.StartsWith($build+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Run directory must be under the candidate build directory.'}
if(Test-Path -LiteralPath $run){throw 'Use a fresh run directory.'}
New-Item -ItemType Directory -Path $run | Out-Null
$launcher=Join-Path $run 'BoundaryProbe.exe'
Copy-Item -LiteralPath (Join-Path $build 'BoundaryProbe.exe') -Destination $launcher
$fixture=Join-Path $run 'Edge-ac'
foreach($part in @('tools','work','out','private')){New-Item -ItemType Directory -Path (Join-Path $fixture $part) -Force|Out-Null}
$url='data:text/html,'+[Uri]::EscapeDataString('<!doctype html><html><head><title>Cage candidate</title></head><body>waiting<script>document.body.textContent="CAGE_EDGE_DATA_PASS";</script></body></html>')
$edgeArgs=@('--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check',
    '--disable-background-networking','--disable-component-update','--disable-sync','--disable-extensions','--disable-quic',
    ('--user-data-dir='+(Join-Path $fixture 'work/profile')),'--enable-logging=stderr','--v=1',
    '--dump-dom','--timeout=10000',$url)
$launcherArgs=@('launch','ac',$fixture,$EdgePath,'25')+$edgeArgs
$text=@(& $launcher @launcherArgs 2>&1|ForEach-Object{$_.ToString()})-join "`n"
$launcherExit=$LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $run 'launcher-output.txt'),$text)
$receipt=Get-Content -LiteralPath (Join-Path $fixture 'launch.json') -Raw|ConvertFrom-Json
$stdout=[IO.File]::ReadAllText((Join-Path $fixture 'out/launch/stdout.txt'))
$stderr=[IO.File]::ReadAllText((Join-Path $fixture 'out/launch/stderr.txt'))
$result=[ordered]@{candidate='data';scope='offline data URL with JavaScript DOM marker';launcherExit=$launcherExit;receipt=$receipt;markerFound=($stdout -match '<body>CAGE_EDGE_DATA_PASS</body>');stdoutBytes=[Text.Encoding]::UTF8.GetByteCount($stdout);stderrBytes=[Text.Encoding]::UTF8.GetByteCount($stderr);noSandboxFlag=$false;hostAclExpanded=$false;passed=$false}
$result.passed=[bool]($result.markerFound -and $receipt.tokenVerified -and $receipt.isAppContainer -and $receipt.capabilityCount -eq 0 -and -not $receipt.isLPAC -and -not $receipt.timedOut -and $receipt.exitCode -eq 0 -and $receipt.profileDeleteResult -eq 0)
$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $run 'result.json') -Encoding utf8
$result|ConvertTo-Json -Depth 6
