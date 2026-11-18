[CmdletBinding()]
param()

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
    'LocalWfpPolicy.cs',
    'LocalProvisioner.cs',
    'LocalProxyBroker.cs',
    'LocalWorkerDaemon.cs',
    'LocalSelfTest.cs',
    'Program.cs'
) | ForEach-Object { Join-Path $PSScriptRoot $_ }

& $compiler /nologo /target:exe /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll "/out:$outputExe" @sources
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

Write-Output "Built: $outputExe"
$selfTestOutput = & $outputExe selftest
if ($LASTEXITCODE -ne 0) {
    throw "SelfTest failed with exit code $LASTEXITCODE"
}
Write-Output $selfTestOutput
