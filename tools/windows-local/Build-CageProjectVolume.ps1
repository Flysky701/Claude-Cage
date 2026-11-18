[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$library = Join-Path ${env:ProgramFiles(x86)} 'WinFsp/bin/winfsp-msil.dll'
if (!(Test-Path -LiteralPath $library -PathType Leaf)) { return }
$src = Join-Path $PSScriptRoot 'LocalProjectFileSystem.cs'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
# Version directories let an existing workbench finish on its loaded driver adapter.
$sourceHash = (Get-FileHash -LiteralPath $src).Hash
$libraryHash = (Get-FileHash -LiteralPath $library).Hash
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $digest = $sha.ComputeHash([Text.Encoding]::ASCII.GetBytes($sourceHash + $libraryHash))
    $version = [BitConverter]::ToString($digest).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }
$parent = Join-Path $OutputDirectory 'project-volume'
$directory = Join-Path $parent $version
[IO.Directory]::CreateDirectory($parent) | Out-Null
if (!(Test-Path -LiteralPath (Join-Path $directory 'CageProjectFileSystem.exe') -PathType Leaf)) {
    $stage = Join-Path $parent ([guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($stage) | Out-Null
    Copy-Item -LiteralPath $library -Destination $stage
    & $compiler /nologo /target:exe /optimize+ /platform:x64 "/r:$library" "/out:$stage\CageProjectFileSystem.exe" $src
    if ($LASTEXITCODE -ne 0) { throw 'Could not build the Windows project filesystem.' }
    try { [IO.Directory]::Move($stage, $directory) }
    catch [IO.IOException] { if (!(Test-Path -LiteralPath (Join-Path $directory 'CageProjectFileSystem.exe') -PathType Leaf)) { throw } }
}
$pointer = Join-Path $parent 'current'
if ((Test-Path -LiteralPath $pointer) -and [IO.File]::ReadAllText($pointer) -eq $version) { return }
$pending = Join-Path $parent ('current-' + [guid]::NewGuid().ToString('N'))
[IO.File]::WriteAllText($pending,$version)
try { [IO.File]::Move($pending,$pointer) }
catch [IO.IOException] {
    if (!(Test-Path -LiteralPath $pointer)) { throw }
    $previous = $pending + '.previous'
    [IO.File]::Replace($pending,$pointer,$previous)
    [IO.File]::Delete($previous)
}
