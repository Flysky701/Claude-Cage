[CmdletBinding()]
param(
    [string]$ProfilePath,
    [int]$BrokerPort = 17981,
    [switch]$Elevate
)

$ErrorActionPreference = 'Stop'
if (-not $ProfilePath) { $ProfilePath = Join-Path $PSScriptRoot '../../tmp/windows-local/profile/local-profile.json' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$resolvedProfile = [IO.Path]::GetFullPath($ProfilePath)
$exe = Join-Path $repo 'tmp/windows-local/CageLocal.exe'
$receiptOut = Join-Path (Split-Path -Parent $resolvedProfile) 'provision-result.json'

if (Test-Path -LiteralPath $resolvedProfile -PathType Leaf) {
    Write-Output "Existing profile found at: $resolvedProfile"
    Get-Content -LiteralPath $resolvedProfile -Raw | Write-Output
    exit 0
}

if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Build CageLocal.exe first using build.ps1."
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$callerSid = $identity.User.Value

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if (-not $Elevate) {
        throw "Provisioning requires one-time Windows Administrator consent. Re-run with -Elevate."
    }
    $arguments = 'provision --controller-sid {0} --profile-out "{1}" --broker-port {2}' -f $callerSid, $resolvedProfile, $BrokerPort
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedProfile) | Out-Null
    $process = Start-Process -FilePath $exe -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
    try {
        if ($process.ExitCode -ne 0) { throw "Elevated provisioning exited with code $($process.ExitCode)." }
    } finally {
        $process.Dispose()
    }
    # The elevated helper writes both protected records before returning.
    $binding = Get-Content -LiteralPath $resolvedProfile -Encoding UTF8 -Raw | ConvertFrom-Json
    $rules = Get-Content -LiteralPath $binding.wfpReceiptFile -Encoding UTF8 -Raw | ConvertFrom-Json
    $result = [ordered]@{
        provisioned = $true
        profilePath = $resolvedProfile
        instanceId = $binding.instanceId
        workerUsername = $binding.workerUsername
        workerSid = $binding.workerSid
        isAdmin = $false
        hiddenFromLogon = $true
        brokerPort = $binding.brokerPort
        wfp = $rules
    } | ConvertTo-Json -Depth 6 -Compress
    [IO.File]::WriteAllText($receiptOut, $result, [Text.UTF8Encoding]::new($false))
    Write-Output $result
    exit 0
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedProfile) | Out-Null
$result = & $exe provision --controller-sid $callerSid --profile-out $resolvedProfile --broker-port $BrokerPort
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
[IO.File]::WriteAllText($receiptOut, ($result -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Output $result
