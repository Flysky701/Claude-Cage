# Local candidate only: one new package, temporary WFP filters, one loopback port.
param(
    [ValidateSet('ac','lpac')][string]$Mode = 'ac',
    [switch]$Elevate,
    [switch]$ProxyRoundTrip,
    [switch]$BuildOnly
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$binary = Join-Path $repo 'tmp/windows-appcontainer/BoundaryProbe.exe'
if ($BuildOnly) {
    & (Join-Path $PSScriptRoot 'verify-boundary.ps1') -BuildOnly
    exit $LASTEXITCODE
}
if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) {
    throw 'Build the candidate first with verify-boundary.ps1 -BuildOnly.'
}
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if (-not $Elevate) { throw 'This package-only network experiment requires Windows administrator consent. Use -Elevate to request it.' }
    # Windows presents its own consent prompt. Never automate that prompt.
    $engine = (Get-Process -Id $PID).Path
    $arguments = '-NoProfile -File "' + $PSCommandPath + '" -Mode ' + $Mode
    if ($ProxyRoundTrip) { $arguments += ' -ProxyRoundTrip' }
    $helper = Start-Process -FilePath $engine -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru
    $helper.WaitForExit()
    exit $helper.ExitCode
}
$record = Join-Path $repo ('tmp/windows-appcontainer/network-console-' + [Guid]::NewGuid().ToString('N') + '.json')
$command = if ($ProxyRoundTrip) { 'network-proxy' } else { 'network' }
& $binary $command $Mode | Tee-Object -FilePath $record
$result = $LASTEXITCODE
Write-Output ('Network experiment record: ' + $record)
exit $result
