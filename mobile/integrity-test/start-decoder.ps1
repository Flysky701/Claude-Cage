[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Credentials,
    [Parameter(Mandatory)][string]$Adb,
    [string]$Serial,
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath $Credentials -PathType Leaf)) { throw 'Service account JSON not found.' }
$deviceArgs = @()
if ($Serial) { $deviceArgs = @('-s', $Serial) }
& $Adb @deviceArgs reverse tcp:8787 tcp:8787
if ($LASTEXITCODE -ne 0) { throw 'Connect one USB debugging device, or specify -Serial.' }
try {
    & $Python (Join-Path $PSScriptRoot 'decode.py') --credentials $Credentials
    if ($LASTEXITCODE -ne 0) { throw 'Decoder exited with an error.' }
} finally {
    & $Adb @deviceArgs reverse --remove tcp:8787
}
