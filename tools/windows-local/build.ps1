[CmdletBinding()]
param(
    [switch]$IfNeeded,
    [switch]$Workbench,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$buildDir = if ($OutputDirectory) { [IO.Path]::GetFullPath($OutputDirectory) } else { Join-Path $repo 'tmp/windows-local' }

$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "Missing C# compiler at $compiler"
}

$sources = @(
    'LocalProfile.cs',
    'LocalWorkbenchServices.cs',
    'LocalWfpPolicy.cs',
    'LocalProvisioner.cs',
    'LocalProxyBroker.cs',
    'LocalWorkerDaemon.cs',
    'LocalSelfTest.cs',
    'LocalWorkbench.cs',
    'LocalWorkbenchTabs.cs',
    'LocalTerminalIsolation.cs',
    'LocalWorkbenchTerminal.cs',
    'LocalClaudeRuntime.cs',
    'LocalWorkbenchSsh.cs',
    'LocalWorkbenchNetwork.cs',
    'LocalWorkbenchBrowser.cs',
    'LocalWorkbenchApps.cs',
    'LocalWorkbenchProjects.cs',
    'LocalWorkbenchVolume.cs',
    'Program.cs'
) | ForEach-Object { Join-Path $PSScriptRoot $_ }

$volumeBuild = Join-Path $PSScriptRoot 'Build-CageProjectVolume.ps1'
$volumeSource = Join-Path $PSScriptRoot 'LocalProjectFileSystem.cs'
$sourceHashes = (Get-FileHash -LiteralPath (@($PSCommandPath, $volumeBuild, $volumeSource) + $sources) -Algorithm SHA256).Hash -join ','
if ($Workbench) {
    # Each live controller keeps the helper it started with until the user exits.
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $digest = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::ASCII.GetBytes($sourceHashes))).Replace('-', '') }
    finally { $sha.Dispose() }
    $buildDir = Join-Path $buildDir ('workbench-' + $digest.Substring(0, 24))
}
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
$outputExe = Join-Path $buildDir 'CageLocal.exe'
& $volumeBuild -OutputDirectory $buildDir | Out-Host
$stamp = Join-Path $buildDir 'helper-build.sha256'
if ($IfNeeded -and (Test-Path -LiteralPath $stamp -PathType Leaf) -and (Test-Path -LiteralPath $outputExe -PathType Leaf)) {
    $current = $sourceHashes + ',' + (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash
    if ([IO.File]::ReadAllText($stamp) -eq $current) {
        if ($Workbench) { return $outputExe }
        Write-Output "Using previously verified build: $outputExe"
        return
    }
}

& $compiler /nologo /target:exe /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll "/out:$outputExe" @sources
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

if (!$Workbench) { Write-Output "Built: $outputExe" }
$selfTestOutput = & $outputExe selftest
if ($LASTEXITCODE -ne 0) {
    throw "SelfTest failed with exit code $LASTEXITCODE"
}
if (!$Workbench) { Write-Output $selfTestOutput }
[IO.File]::WriteAllText($stamp, $sourceHashes + ',' + (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash)
if ($Workbench) { return $outputExe }
