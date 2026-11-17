param([ValidateSet('ac','lpac','both')][string]$Mode='both',[switch]$BuildOnly,[switch]$Native,[string]$GoPath)
$ErrorActionPreference='Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build = Join-Path $repo 'tmp/windows-appcontainer'
New-Item -ItemType Directory -Force -Path $build | Out-Null
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$binary = Join-Path $build 'BoundaryProbe.exe'
& $compiler /nologo /target:exe /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll "/out:$binary" (Join-Path $PSScriptRoot 'BoundaryProbe.cs') (Join-Path $PSScriptRoot 'BoundaryNetwork.cs') (Join-Path $PSScriptRoot 'BoundaryTerminal.cs') (Join-Path $PSScriptRoot 'BoundaryTerminalRpc.cs')
if ($LASTEXITCODE -ne 0) { throw 'Probe compilation failed' }
if ($Native) {
    if (-not $GoPath) {
        $goCommand = Get-Command go.exe -ErrorAction SilentlyContinue
        if ($goCommand) { $GoPath = $goCommand.Source }
        else { throw 'Native probe requires a local Go compiler; supply -GoPath.' }
    }
    $env:GOTOOLCHAIN='local'
    $env:GOCACHE=Join-Path $build 'go-cache'
    & $GoPath build -o (Join-Path $build 'BoundaryWorker.exe') (Join-Path $PSScriptRoot 'BoundaryWorker.go')
    if ($LASTEXITCODE -ne 0) { throw 'Native probe compilation failed' }
}
if ($BuildOnly) { Write-Output $binary; exit 0 }
$modes = if ($Mode -eq 'both') { @('ac','lpac') } else { @($Mode) }
$failed = $false
foreach ($candidate in $modes) {
    $command = if ($Native) { 'native-suite' } else { 'suite' }
    & $binary $command $candidate
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}
if ($failed) { exit 1 }
