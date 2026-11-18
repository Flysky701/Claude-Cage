[CmdletBinding()]
param([switch]$IfNeeded)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$buildDir = Join-Path $repo 'tmp/windows-local'
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "Missing C# compiler at $compiler"
}

$outputExe = Join-Path $buildDir 'CageLocal.exe'
$sources = @(
    'LocalProfile.cs',
    'LocalWorkbenchServices.cs',
    'LocalWfpPolicy.cs',
    'LocalProvisioner.cs',
    'LocalProxyBroker.cs',
    'LocalWorkerDaemon.cs',
    'LocalSelfTest.cs',
    'LocalWorkbench.cs',
    'LocalTerminalIsolation.cs',
    'LocalWorkbenchTerminal.cs',
    'LocalWorkbenchSsh.cs',
    'LocalWorkbenchNetwork.cs',
    'LocalWorkbenchBrowser.cs',
    'LocalWorkbenchApps.cs',
    'LocalWorkbenchProjects.cs',
    'Program.cs'
) | ForEach-Object { Join-Path $PSScriptRoot $_ }

$stamp = Join-Path $buildDir 'helper-build.sha256'
$sourceHashes = (Get-FileHash -LiteralPath (@($PSCommandPath) + $sources) -Algorithm SHA256).Hash -join ','
if ($IfNeeded -and (Test-Path -LiteralPath $stamp -PathType Leaf) -and (Test-Path -LiteralPath $outputExe -PathType Leaf)) {
    $current = $sourceHashes + ',' + (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash
    if ([IO.File]::ReadAllText($stamp) -eq $current) {
        Write-Output "Using previously verified build: $outputExe"
        return
    }
}

& $compiler /nologo /target:exe /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll "/out:$outputExe" @sources
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

Write-Output "Built: $outputExe"
$selfTestOutput = & $outputExe selftest
if ($LASTEXITCODE -ne 0) {
    throw "SelfTest failed with exit code $LASTEXITCODE"
}
Write-Output $selfTestOutput
[IO.File]::WriteAllText($stamp, $sourceHashes + ',' + (Get-FileHash -LiteralPath $outputExe -Algorithm SHA256).Hash)
