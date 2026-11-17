[CmdletBinding()]
param(
    [ValidateSet('ac','lpac','both')][string]$Mode = 'both',
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '../../tmp/windows-appcontainer/desktop-source/extracted/app'),
    [string]$RunDirectory,
    [ValidateRange(5,60)][int]$ObservationSeconds = 20
)

# Offline launch observation only. No package registration, service setup,
# network capabilities, login, or --no-sandbox compatibility shortcut.
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build = Join-Path $repo 'tmp/windows-appcontainer'
$source = [IO.Path]::GetFullPath($SourceDirectory)
$sourceExe = Join-Path $source 'Claude.exe'
$launcherSource = Join-Path $build 'BoundaryProbe.exe'
if (-not (Test-Path -LiteralPath $launcherSource -PathType Leaf)) { throw 'Build BoundaryProbe first.' }
if (-not (Test-Path -LiteralPath $sourceExe -PathType Leaf)) { throw 'Prepare the official Desktop app files first.' }
if (@(Get-ChildItem -LiteralPath $source -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
    throw 'Application source includes redirected paths; preserve it and use the plain official extraction.'
}
if (-not $RunDirectory) { $RunDirectory = Join-Path $build ('desktop-' + [guid]::NewGuid().ToString('N').Substring(0,12)) }
$run = [IO.Path]::GetFullPath($RunDirectory)
if (-not $run.StartsWith($build + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'RunDirectory must be below tmp/windows-appcontainer.'
}
if (Test-Path -LiteralPath $run) { throw 'RunDirectory exists; use a fresh directory to preserve earlier results.' }
New-Item -ItemType Directory -Path $run | Out-Null
# Freeze this tested launcher without changing the other agents' build.
$launcher = Join-Path $run 'BoundaryProbe.exe'
Copy-Item -LiteralPath $launcherSource -Destination $launcher
$modes = if ($Mode -eq 'both') { @('ac','lpac') } else { @($Mode) }
$utf8 = [Text.UTF8Encoding]::new($false)
$results = [Collections.Generic.List[object]]::new()

foreach ($candidate in $modes) {
    $fixture = Join-Path $run ('Desktop-' + $candidate)
    foreach ($part in @('tools','work','out','private')) {
        New-Item -ItemType Directory -Path (Join-Path $fixture $part) -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $fixture 'tools/app') -Recurse
    $executable = Join-Path $fixture 'tools/app/Claude.exe'
    $profile = Join-Path $fixture 'work/profile'
    $launchArguments = @('launch', $candidate, $fixture, $executable, [string]$ObservationSeconds,
                        ('--user-data-dir=' + $profile), '--disable-gpu', '--enable-logging=stderr',
                        '--disable-background-networking', '--disable-component-update', '--disable-sync')
    Write-Host ('Observing Claude Desktop in {0} for at most {1} seconds.' -f $candidate, $ObservationSeconds)
    $raw = @(& $launcher @launchArguments 2>&1 | ForEach-Object { $_.ToString() }) -join "`n"
    $launcherExit = $LASTEXITCODE
    [IO.File]::WriteAllText((Join-Path $fixture 'launcher-output.txt'), $raw, $utf8)
    $receiptFile = Join-Path $fixture 'launch.json'
    $receipt = if (Test-Path -LiteralPath $receiptFile) { Get-Content -LiteralPath $receiptFile -Raw | ConvertFrom-Json } else { $null }
    $row = [ordered]@{
        app='Claude Desktop'; mode=$candidate; version=(Get-Item -LiteralPath $sourceExe).VersionInfo.ProductVersion
        scope='offline application launch observation only'; launcherExit=$launcherExit
        receipt=$receipt; windowVerified=$false; chatVerified=$false; codeVerified=$false; signedIn=$false
        networkCapabilities=0; cowork='outside this test'; assessment='not verified'
    }
    if ($receipt -and $receipt.tokenVerified) {
        $row.assessment = if ($receipt.timedOut) {
            'process started with verified token; stopped at observation limit; UI unverified'
        } elseif ($receipt.exitCode -ne 0) {
            'process started with verified token, then application exited abnormally; UI compatibility not passed'
        } else {
            'process started with verified token and exited; UI unverified'
        }
    }
    if ($receipt -and $receipt.error) { $row.assessment='launcher or token validation failed' }
    $results.Add($row)
    [IO.File]::WriteAllText((Join-Path $run 'results.json'), (@{schema=1;results=@($results.ToArray())}|ConvertTo-Json -Depth 8), $utf8)
    $row | ConvertTo-Json -Depth 8 | Write-Output
}
